import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:new_uber/common/controller/services/toast_services.dart';
import 'package:new_uber/common/model/ride_request_model.dart';
import 'package:new_uber/constant/constants.dart';

class RideRequestServices {
  static Future<void> createNewRideRequest(
    RideRequestModel rideRequestModel,
    BuildContext context,
  ) async {
    if (!context.mounted) return;

    try {
      final ref = FirebaseDatabase.instance.ref().child(
        'RideRequest/${auth.currentUser!.phoneNumber}',
      );

      await ref.set(rideRequestModel.toMap());

      if (!context.mounted) return;

      ToastServices.sendScaffoldAlert(
        msg: 'Ride Request Registered Successfully',
        toastStatus: 'SUCCESS',
        context: context,
      );
    } catch (error) {
      if (!context.mounted) return;

      ToastServices.sendScaffoldAlert(
        msg: 'Error Creating New Ride Request',
        toastStatus: 'ERROR',
        context: context,
      );
      throw Exception(error);
    }
  }

  static getRideStatus(int rideStatusNum) {
    switch (rideStatusNum) {
      case 0:
        return 'WAITING_FOR_RIDE_REQUEST';
      case 1:
        return 'WAITING_FOR_DRIVER_TO_ARRIVE';

      case 2:
        return 'MOVING_TOWARDS_DESTINATION';

      case 3:
        return 'RIDE_COMPLETED';
    }
  }

  static cancleRideRequest(BuildContext context) {
    FirebaseDatabase.instance
        .ref()
        .child('RideRequest/${auth.currentUser!.phoneNumber}')
        .remove()
        .then((value) {});
    Navigator.pop(context);
  }

  static getRideHistory(BuildContext context) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref().child(
      'RideHistoryRider/${auth.currentUser!.phoneNumber}',
    );
    try {
      DatabaseEvent event = await ref
          .orderByChild('rideEndTime')
          .limitToLast(2)
          .once();
      log(event.snapshot.value.toString());
    } catch (e) {
      throw Exception(e);
    }
  }
}
