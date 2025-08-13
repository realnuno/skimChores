
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:new_uber/common/controller/services/location_services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:new_uber/constant/constants.dart';
import 'package:new_uber/driver/controller/provider/location_provider_driver.dart';

class GeoFireServices {
  static DatabaseReference databaseRef = FirebaseDatabase.instance.ref().child(
    'User/${auth.currentUser!.phoneNumber}/driverStatus',
  );

  static goOnline() async {
    LatLng? currentPosition = await LocationServices.getCurrentLocation();
    if (currentPosition == null) {
      // Handle case where location permission is denied
      return;
    }
    
    Geofire.initialize('OnlineDrivers');
    Geofire.setLocation(
      auth.currentUser!.phoneNumber!,
      currentPosition.latitude,
      currentPosition.longitude,
    );
    databaseRef.set('ONLINE');
    databaseRef.onValue.listen((event) {});
  }

  static goOffline(BuildContext context) {
    Geofire.initialize("OnlineDrivers");
    Geofire.removeLocation(auth.currentUser!.phoneNumber!);
    databaseRef.set('OFFLINE');
    databaseRef.onDisconnect();
  }

  static updateLocationRealTime(BuildContext context) async {
    // Capture the provider before any async gap
    final locationProvider = context.read<LocationProviderDriver>();
    final userPhone = FirebaseAuth.instance.currentUser?.phoneNumber;

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Don't proceed if permission is still not granted
        return;
      }
    }

    // Define settings
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10,
    );

    // Start location stream
    Geolocator.getPositionStream(locationSettings: locationSettings).listen((
      event,
    ) {
      locationProvider.updateDriverPosition(event);

      if (userPhone != null) {
        Geofire.setLocation(userPhone, event.latitude, event.longitude);
      }
    });
  }
}
