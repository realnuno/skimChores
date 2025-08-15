import 'dart:convert';
import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:new_uber/common/model/profile_data_model.dart';
import 'package:new_uber/common/model/ride_request_model.dart';
import 'package:new_uber/constant/constants.dart';
import 'package:new_uber/driver/view/homeScreenDriver/driver_home_screen.dart';
import 'package:new_uber/driver/view/homeScreenDriver/trip_screen.dart';
import 'package:new_uber/common/controller/services/firebasePushNotificatinServices/push_notification_dialogue.dart';

class DriverHomeScreeBuilder extends StatefulWidget {
  const DriverHomeScreeBuilder({super.key});

  @override
  State<DriverHomeScreeBuilder> createState() => _DriverHomeScreeBuilderState();
}

class _DriverHomeScreeBuilderState extends State<DriverHomeScreeBuilder> {
  DatabaseReference driverProfileRef = FirebaseDatabase.instance
      .ref()
      .child('User/${auth.currentUser!.phoneNumber}');
      
  // Add ride request listener
  DatabaseReference rideRequestsRef = FirebaseDatabase.instance
      .ref()
      .child('RideRequest');
      
  // Track previous ride count to detect new requests
  int previousRideCount = 0;
  bool hasShownNotification = false;
  String? lastShownRideKey;
  Map<String, DateTime> deniedRequests = {}; // key: riderID, value: deny time

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: driverProfileRef.onValue,
        builder: (context, profileEvent) {
          if (profileEvent.connectionState == ConnectionState.waiting) {
            return const HomeScreenDriver();
          }
          if (profileEvent.data != null) {
            ProfileDataModel profileData = ProfileDataModel.fromMap(
                jsonDecode(jsonEncode(profileEvent.data!.snapshot.value))
                    as Map<String, dynamic>);
            if (profileData.activeRideRequestID != null) {
              return TripScreen(rideID: profileData.activeRideRequestID!);
            } else {
              // Show home screen with ride request listener
              return StreamBuilder(
                stream: rideRequestsRef.onValue,
                builder: (context, rideEvent) {
                  if (rideEvent.connectionState == ConnectionState.waiting) {
                    return const HomeScreenDriver();
                  }
                  // Check for available ride requests
                  if (rideEvent.data != null && rideEvent.data!.snapshot.value != null) {
                    Map<dynamic, dynamic> rideRequests = 
                        Map<dynamic, dynamic>.from(rideEvent.data!.snapshot.value as Map);
                    final now = DateTime.now();
                    // Clean up deniedRequests entries older than 10 minutes
                    deniedRequests.removeWhere((key, deniedAt) => now.difference(deniedAt).inMinutes >= 10);
                    // Find ride requests without drivers, filter out denied
                    List<MapEntry<dynamic, dynamic>> availableRides = rideRequests.entries
                        .where((entry) {
                          try {
                            Map<String, dynamic> rideData = Map<String, dynamic>.from(entry.value as Map);
                            final riderId = rideData['riderProfile']?['mobileNumber'];
                            if (riderId != null && deniedRequests.containsKey(riderId)) {
                              return false; // Denied within last 10 minutes
                            }
                            return rideData['driverProfile'] == null && 
                                   rideData['rideStatus'] == 'WAITING_FOR_RIDE_REQUEST';
                          } catch (e) {
                            return false;
                          }
                        })
                        .toList();
                    if (availableRides.isNotEmpty) {
                      log('Found ${availableRides.length} available ride requests');
                      final firstRideKey = availableRides.first.key.toString();
                      if ((!hasShownNotification || lastShownRideKey != firstRideKey)) {
                        log('🚨 New or re-shown ride request detected! Showing notification...');
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _showNewRideNotification(availableRides.first);
                        });
                        hasShownNotification = true;
                        lastShownRideKey = firstRideKey;
                      }
                      previousRideCount = availableRides.length;
                    } else {
                      // Reset tracking when no rides available
                      previousRideCount = 0;
                      hasShownNotification = false;
                      lastShownRideKey = null;
                    }
                  }
                  return const HomeScreenDriver();
                },
              );
            }
          } else {
            return const HomeScreenDriver();
          }
        });
  }

  void _showNewRideNotification(MapEntry<dynamic, dynamic> rideEntry) {
    try {
      // Fix type casting issue by using jsonEncode/jsonDecode to convert Firebase types
      Map<String, dynamic> rideData = 
          jsonDecode(jsonEncode(rideEntry.value)) as Map<String, dynamic>;
      
      RideRequestModel rideRequestModel = RideRequestModel.fromMap(rideData);
      final riderId = rideData['riderProfile']?['mobileNumber'];
      // Show the existing PushNotificationDialouge
      PushNotificationDialouge.rideRequestDialogue(
        rideRequestModel,
        context,
        onDeny: () {
          setState(() {
            hasShownNotification = false;
            lastShownRideKey = null;
            if (riderId != null) {
              deniedRequests[riderId] = DateTime.now();
            }
          });
        },
      );
      
      log('✅ Showing push notification dialogue for ride: ${rideEntry.key}');
    } catch (e) {
      log('❌ Error showing ride notification: $e');
      log('Ride data: ${rideEntry.value}');
      log('Ride data type: ${rideEntry.value.runtimeType}');
    }
  }
}