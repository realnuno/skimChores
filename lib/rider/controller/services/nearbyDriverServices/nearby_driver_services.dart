import 'dart:developer';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:new_uber/rider/controller/provider/tripProvider/ride_request_provider.dart';
import 'package:new_uber/rider/model/nearby_drivers_model.dart';

class NearbyDriverServices {
  static getNearbyDrivers(
    LatLng pickupLocation,
    RideRequestProvider rideRequestProvider,
  ) {
    Geofire.initialize('OnlineDrivers');

    Geofire.queryAtLocation(
      pickupLocation.latitude,
      pickupLocation.longitude,
      20,
    )!
        .listen((event) {
      if (event != null) {
        log('Event is Not Null');
        var callback = event['callBack'];

        switch (callback) {
          case Geofire.onKeyEntered:
            NearByDriversModel model = NearByDriversModel(
              driverID: event['key'],
              latitude: event['latitude'],
              longitude: event['longitude'],
            );
            rideRequestProvider.addDriver(model);

            if (rideRequestProvider.fetchNearbyDrivers == true) {
              rideRequestProvider.updateMarker();
            }
            break;

          case Geofire.onKeyExited:
            rideRequestProvider.removeDriver(event['key'].toString());
            rideRequestProvider.updateMarker();
            log('Driver Removed ${event['key']}');
            break;

          case Geofire.onKeyMoved:
            NearByDriversModel model = NearByDriversModel(
              driverID: event['key'],
              latitude: event['latitude'],
              longitude: event['longitude'],
            );
            rideRequestProvider.updateNearbyLocation(model);
            rideRequestProvider.updateMarker();
            break;

          case Geofire.onGeoQueryReady:
            log(rideRequestProvider.nearbyDrivers.length.toString());
            rideRequestProvider.updateMarker();
            break;
        }
      } else {
        log('Event is Null');
      }
    });
  }
}
