import 'dart:async';
import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:new_uber/common/controller/services/location_services.dart';
import 'package:new_uber/constant/constants.dart';
import 'package:new_uber/constant/utils/colors.dart';
import 'package:new_uber/constant/utils/textStyles.dart';
import 'package:new_uber/driver/controller/services/geofire_services.dart';
import 'package:new_uber/driver/controller/services/maps_provider_driver.dart';

class HomeScreenDriver extends StatefulWidget {
  const HomeScreenDriver({super.key});

  @override
  State<HomeScreenDriver> createState() => _HomeScreenDriverState();
}

class _HomeScreenDriverState extends State<HomeScreenDriver> {
  Completer<GoogleMapController> mapControllerDriver = Completer();
  GoogleMapController? mapController;
  String? _driverStatus;
  bool _isProcessingSwipe = false;

  @override
  void initState() {
    super.initState();
    final driverStatusRef = FirebaseDatabase.instance
      .ref()
      .child('User/${auth.currentUser!.phoneNumber}/driverStatus');
    driverStatusRef.onValue.listen((event) {
      final status = event.snapshot.value as String?;
      if (mounted) setState(() => _driverStatus = status);
      if (status == 'ONLINE') {
        GeoFireServices.updateLocationRealTime(context);
      }
    });
  }

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
                  child: _buildSwipeButton(
                    text: _driverStatus == 'ONLINE' ? 'Go Offline' : 'Go Online',
                    onSwipe: _driverStatus == 'ONLINE' ? _handleGoOffline : _handleGoOnline,
                    isProcessing: _isProcessingSwipe,
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
  
  Widget _buildSwipeButton({
    required String text,
    required VoidCallback onSwipe,
    required bool isProcessing,
  }) {
    return SwipeButton(
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
      onSwipe: isProcessing ? null : onSwipe,
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