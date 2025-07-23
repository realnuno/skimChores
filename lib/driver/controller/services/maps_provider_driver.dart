import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsProviderDriver extends ChangeNotifier {
  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(38.8462, -77.3064), // Fairfax, VA
    zoom: 14.4746,
  );

  final Completer<GoogleMapController> mapControllerDriver =
      Completer<GoogleMapController>();

  LatLng? currentLocation;

  updateCurrentLocation(LatLng newLocation) {
    currentLocation = newLocation;
    notifyListeners();
  }
}
