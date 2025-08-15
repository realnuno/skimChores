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
  
  // Reset notification flag when needed
  void _resetNotificationFlag() {
    hasShownNotification = false;
    log('🔄 Notification flag reset - ready for new notifications');
  }
      
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
                    
                    // Find ride requests without drivers
                    List<MapEntry<dynamic, dynamic>> availableRides = rideRequests.entries
                        .where((entry) {
                          try {
                            Map<String, dynamic> rideData = 
                                Map<String, dynamic>.from(entry.value as Map);
                            // Check if ride has no driver and is waiting
                            return rideData['driverProfile'] == null && 
                                   rideData['rideStatus'] == 'WAITING_FOR_RIDE_REQUEST';
                          } catch (e) {
                            return false;
                          }
                        })
                        .toList();
                    
                    if (availableRides.isNotEmpty) {
                      log('Found ${availableRides.length} available ride requests');
                      
                      // Check if this is a new ride request (count increased)
                      if (availableRides.length > previousRideCount && !hasShownNotification) {
                        log('🚨 New ride request detected! Showing notification...');
                        
                        // Schedule notification to show after build is complete
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _showNewRideNotification(availableRides.first);
                        });
                        
                        // Update tracking
                        previousRideCount = availableRides.length;
                        hasShownNotification = true;
                      } else if (availableRides.length != previousRideCount) {
                        // Update count if it changed
                        previousRideCount = availableRides.length;
                        
                        // If count decreased (ride was accepted), reset notification flag
                        if (availableRides.length < previousRideCount) {
                          _resetNotificationFlag();
                        }
                      }
                    } else {
                      // Reset tracking when no rides available
                      previousRideCount = 0;
                      hasShownNotification = false;
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
      
      // Show the existing PushNotificationDialouge
      PushNotificationDialouge.rideRequestDialogue(rideRequestModel, context);
      
      log('✅ Showing push notification dialogue for ride: ${rideEntry.key}');
    } catch (e) {
      log('❌ Error showing ride notification: $e');
      log('Ride data: ${rideEntry.value}');
      log('Ride data type: ${rideEntry.value.runtimeType}');
    }
  }
}