import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:new_uber/common/controller/services/location_services.dart';
import 'package:new_uber/common/model/direction_model.dart';
import 'package:new_uber/common/model/pickup_n_drop_location_model.dart';
import 'package:new_uber/common/model/ride_request_model.dart';
import 'package:new_uber/constant/constants.dart';
import 'package:new_uber/constant/utils/colors.dart';

class RideRequestProviderDriver extends ChangeNotifier {
  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(38.8462, -77.3064),
    zoom: 14,
  );
  Set<Marker> driverMarker = <Marker>{};
  Set<Polyline> polylineSet = {};
  Polyline? polyline;
  List<LatLng> polylineCoordinatesList = [];
  DirectionModel? directionDetails;
  BitmapDescriptor? carIconForMap;
  BitmapDescriptor? destinationIconForMap;
  BitmapDescriptor? pickupIconForMap;
  bool updateMarkerBool = false;
  PickupNDropLocationModel? dropLocation;
  PickupNDropLocationModel? pickupLocation;
  RideRequestModel? rideRequestData;
  bool movingFromCurrentLocationTopickupLocation = false;
  LatLng? rideAcceptLocation;



  updateTripPickupAndDropLoction(
    PickupNDropLocationModel pickupData,
    PickupNDropLocationModel dropData,
  ) {
    pickupLocation = pickupData;
    dropLocation = dropData;
    notifyListeners();
  }

  updateMovingFromCurrentLocationToPickupLocationStatus(bool newStatus) {
    movingFromCurrentLocationTopickupLocation = newStatus;
    notifyListeners();
  }

  updateUpdateMarkerStatus(bool newStatus) {
    updateMarkerBool = newStatus;
    notifyListeners();
  }

  updateRideAcceptLocation(LatLng location) {
    rideAcceptLocation = location;
    notifyListeners();
  }

  updateDirection(DirectionModel newDirection) {
    directionDetails = newDirection;
    notifyListeners();
  }

  updateRideRequestData(RideRequestModel data) {
    rideRequestData = data;
    notifyListeners();
  }

  createIcons(BuildContext context) {
    if (pickupIconForMap == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(
        context,
        size: const Size(2, 2),
      );
      BitmapDescriptor.asset(
            imageConfiguration,
            'assets/images/icons/pickupPngSmall.png',
          ) // Fixed
          .then((icon) {
            pickupIconForMap = icon;
            notifyListeners();
          });
    }
    if (destinationIconForMap == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(
        context,
        size: const Size(2, 2),
      );
      BitmapDescriptor.asset(
            imageConfiguration,
            'assets/images/icons/dropPngSmall.png',
          ) // Fixed
          .then((icon) {
            destinationIconForMap = icon;
            notifyListeners();
          });
    }
    if (carIconForMap == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(
        context,
        size: const Size(2, 2),
      );
      BitmapDescriptor.asset(
            imageConfiguration,
            'assets/images/vehicle/mapCar.png',
          ) // Fixed
          .then((icon) {
            carIconForMap = icon;
            notifyListeners();
          });
    }
  }

  updateMarker() async {
    driverMarker = <Marker>{};
    log('Driver Marker Is Empty');
    log(driverMarker.isEmpty.toString());
    Marker pickupMarker = Marker(
      markerId: const MarkerId('PickupMarker'),
      position: movingFromCurrentLocationTopickupLocation
          ? rideAcceptLocation!
          : LatLng(pickupLocation!.latitude!, pickupLocation!.longitude!),
      icon: pickupIconForMap!,
    );
    Marker destinationMarker = Marker(
      markerId: const MarkerId('PickupMarker'),
      position: movingFromCurrentLocationTopickupLocation
          ? LatLng(pickupLocation!.latitude!, pickupLocation!.longitude!)
          : LatLng(dropLocation!.latitude!, dropLocation!.longitude!),
      icon: destinationIconForMap!,
    );

    if (updateMarkerBool == true) {
      LatLng crrLocation = await LocationServices.getCurrentLocation();
      Marker carMarker = Marker(
        markerId: MarkerId(auth.currentUser!.phoneNumber!),
        position: LatLng(crrLocation.latitude, crrLocation.longitude),
        icon: carIconForMap!,
      );
      driverMarker.add(carMarker);
    }
    driverMarker.add(pickupMarker);
    driverMarker.add(destinationMarker);
    notifyListeners();
    if (updateMarkerBool == true) {
      await Future.delayed(const Duration(seconds: 5), () async {
        await updateMarker();
      });
    }
  }

  decodePolylineAndUpdatePolylineField() {
    PolylinePoints polylinePoints = PolylinePoints();
    polylineCoordinatesList.clear();
    polylineSet.clear();
    List<PointLatLng> data = polylinePoints.decodePolyline(
      directionDetails!.polylinePoints,
    );

    if (data.isNotEmpty) {
      for (var latLngPoints in data) {
        polylineCoordinatesList.add(
          LatLng(latLngPoints.latitude, latLngPoints.longitude),
        );
      }
    }
    polyline = Polyline(
      polylineId: const PolylineId('TripPolyline'),
      color: black,
      points: polylineCoordinatesList,
      jointType: JointType.round,
      width: 3,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      geodesic: true,
    );
    polylineSet.add(polyline!);

    notifyListeners();
  }
}
