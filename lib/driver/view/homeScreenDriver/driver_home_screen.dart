import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:new_uber/common/controller/services/location_services.dart';
import 'package:new_uber/common/model/profile_data_model.dart';
import 'package:new_uber/constant/constants.dart';
import 'package:new_uber/constant/utils/colors.dart';
import 'package:new_uber/constant/utils/textStyles.dart';
import 'package:new_uber/driver/controller/services/geofire_services.dart';
import 'package:new_uber/driver/controller/services/maps_provider_driver.dart';
import 'package:new_uber/driver/controller/services/rideRequestServices/ride_request_services.dart';

class HomeScreenDriver extends StatefulWidget {
  const HomeScreenDriver({super.key});

  @override
  State<HomeScreenDriver> createState() => _HomeScreenDriverState();
}

class _HomeScreenDriverState extends State<HomeScreenDriver> {
  Completer<GoogleMapController> mapControllerDriver = Completer();
  GoogleMapController? mapController;
  DatabaseReference driverProfileRef = FirebaseDatabase.instance
      .ref()
      .child('User/${auth.currentUser!.phoneNumber}');
      
  // Add flag to prevent multiple executions
  bool _isProcessingSwipe = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size(100.w, 10.h),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.h,
            ),
            child: Row(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: driverProfileRef.onValue,
                    builder: (context, event) {
                      if (event.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: black,
                          ),
                        );
                      }
                      
                      if (event.data == null) {
                        return _buildSwipeButton(
                          text: 'Go Online',
                          onSwipe: _handleGoOnline,
                        );
                      }
                      
                      try {
                        ProfileDataModel profileData = ProfileDataModel.fromMap(
                            jsonDecode(jsonEncode(event.data!.snapshot.value))
                                as Map<String, dynamic>);
                        
                        log(profileData.driverStatus.toString());
                        
                        if (profileData.driverStatus == 'ONLINE') {
                          return _buildSwipeButton(
                            text: 'Go Offline',
                            onSwipe: _handleGoOffline,
                          );
                        } else {
                          return _buildSwipeButton(
                            text: 'Go Online',
                            onSwipe: _handleGoOnline,
                          );
                        }
                      } catch (e) {
                        log('Error parsing profile data: $e');
                        return Center(
                          child: CircularProgressIndicator(
                            color: black,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            Consumer<MapsProviderDriver>(
                builder: (context, mapProvider, child) {
              return GoogleMap(
                initialCameraPosition: mapProvider.initialCameraPosition,
                mapType: MapType.normal,
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
                zoomControlsEnabled: true,
                zoomGesturesEnabled: true,
                onMapCreated: (GoogleMapController controller) async {
                  mapControllerDriver.complete(controller);
                  mapController = controller;
                  LatLng? crrLocation =
                      await LocationServices.getCurrentLocation();
                  if (crrLocation != null) {
                    CameraPosition cameraPosition = CameraPosition(
                      target: crrLocation,
                      zoom: 14,
                    );
                    mapController!.animateCamera(
                        CameraUpdate.newCameraPosition(cameraPosition));
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }
  
  // Extract reusable SwipeButton widget
  Widget _buildSwipeButton({
    required String text,
    required VoidCallback onSwipe,
  }) {
    return SwipeButton(
      key: ValueKey('swipe_$text'), // Add unique key to prevent recreation
      thumbPadding: EdgeInsets.all(1.w),
      thumb: Icon(
        Icons.chevron_right,
        color: white,
      ),
      inactiveThumbColor: black,
      activeThumbColor: black,
      inactiveTrackColor: greyShade3,
      activeTrackColor: greyShade3,
      elevationThumb: 2,
      elevationTrack: 2,
      onSwipe: onSwipe,
      child: Text(
        text,
        style: AppTextStyles.body16Bold,
      ),
    );
  }
  
  // Extract swipe handlers to prevent recreation
  Future<void> _handleGoOnline() async {
    if (_isProcessingSwipe) return;
    _isProcessingSwipe = true;
    
    try {
      log('Button is Swiped - Going Online');
      await GeoFireServices.goOnline();
      await GeoFireServices.updateLocationRealTime(context);
    } finally {
      // Reset flag after a delay to prevent rapid re-triggering
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _isProcessingSwipe = false;
          });
        }
      });
    }
  }
  
  Future<void> _handleGoOffline() async {
    if (_isProcessingSwipe) return;
    _isProcessingSwipe = true;
    
    try {
      log('Button is Swiped - Going Offline');
      await GeoFireServices.goOffline(context);
    } finally {
      // Reset flag after a delay to prevent rapid re-triggering
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _isProcessingSwipe = false;
          });
        }
      });
    }
  }
}