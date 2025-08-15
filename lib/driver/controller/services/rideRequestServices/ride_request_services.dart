// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:new_uber/common/controller/provider/profile_data_provider.dart';
import 'package:new_uber/common/controller/services/toast_services.dart';
import 'package:new_uber/common/model/profile_data_model.dart';
import 'package:new_uber/common/model/ride_request_model.dart';
import 'package:new_uber/constant/constants.dart';
import 'package:new_uber/driver/controller/provider/ride_request_provider.dart';
import 'package:uuid/uuid.dart';

class RideRequestServicesDriver {
  static checkRideAvailability(BuildContext context, String rideID) async {
    DatabaseReference? tripRef = FirebaseDatabase.instance.ref().child(
      'RideRequest/$rideID',
    );
    final snapshot = await tripRef.get();
    if (snapshot.exists) {
      Stream<DatabaseEvent> stream = tripRef.onValue;
      stream.listen((event) async {
        final checkSnapshotExists = await tripRef.get();
        if (checkSnapshotExists.exists) {
          RideRequestModel rideRequestModel = RideRequestModel.fromMap(
            jsonDecode(jsonEncode(snapshot.value)) as Map<String, dynamic>,
          );
          if (rideRequestModel.driverProfile != null) {
            audioPlayer.stop();
            if (context.mounted) Navigator.pop(context);
            if (!context.mounted) return;
            ToastServices.sendScaffoldAlert(
              msg: 'Opps! Trip accepted by someone',
              toastStatus: 'ERROR',
              context: context,
            );
          }
        } else {
          audioPlayer.stop();
          if (context.mounted) Navigator.pop(context);
          if (!context.mounted) return;
          ToastServices.sendScaffoldAlert(
            msg: 'Opps! Ride Was Cancelled',
            toastStatus: 'ERROR',
            context: context,
          );
        }
      });
    } else {
      if (context.mounted) Navigator.pop(context);
    }
  }

  static getRideRequestData(String rideID) async {
    DatabaseReference? tripRef = FirebaseDatabase.instance.ref().child(
      'RideRequest/$rideID',
    );
    final snapshot = await tripRef.get();
    if (snapshot.exists) {
      RideRequestModel rideRequestModel = RideRequestModel.fromMap(
        jsonDecode(jsonEncode(snapshot.value)) as Map<String, dynamic>,
      );
      return rideRequestModel;
    }
  }

  static updateRideRequestStatus(String rideRequestStatus, String rideID) {
    DatabaseReference tripRef = FirebaseDatabase.instance.ref().child(
      'RideRequest/$rideID/rideStatus',
    );
    tripRef.set(rideRequestStatus);
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

  static updateRideRequestID(String rideID) {
    DatabaseReference tripRef = FirebaseDatabase.instance.ref().child(
      'User/${auth.currentUser!.phoneNumber}/activeRideRequestID',
    );
    tripRef.set(rideID);
  }

  static Future<void> acceptRideRequest(
    String rideID,
    BuildContext context,
  ) async {
    if (!context.mounted) return;

    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref().child(
        'RideRequest/$rideID/driverProfile',
      );

      ProfileDataModel profileData = context
          .read<ProfileDataProvider>()
          .profileData!;

      await ref.set(profileData.toMap());

      if (!context.mounted) return;

      ToastServices.sendScaffoldAlert(
        msg: 'Ride Request Registered Successfully',
        toastStatus: 'SUCCESS',
        context: context,
      );
    } catch (error) {
      if (!context.mounted) return;

      ToastServices.sendScaffoldAlert(
        msg: 'Oops! Unable to Register Ride',
        toastStatus: 'ERROR',
        context: context,
      );

      throw Exception(error);
    }
  }

  static Future<void> endRide(String rideID, BuildContext context) async {
    if (!context.mounted) return;

    try {
      final uuid = const Uuid();
      final uniqueID = uuid.v1().toString();

      final db = FirebaseDatabase.instance.ref();

      final rideRef = db.child('RideRequest/$rideID/rideEndTime');
      final rideDataRef = db.child('RideRequest/$rideID');
      final riderHistoryRef = db.child('RideHistoryRider/$rideID/$uniqueID');
      final driverHistoryRef = db.child('RideHistoryDriver/$rideID/$uniqueID');
      final driverActiveRef = db.child(
        'User/${auth.currentUser!.phoneNumber}/activeRideRequestID',
      );

      // Stop live location updates
      context.read<RideRequestProviderDriver>().updateUpdateMarkerStatus(false);

      // Save ride end time
      await rideRef.set(DateTime.now().microsecondsSinceEpoch);

      // Fetch full ride data before removing
      final snapshot = await rideDataRef.get();

      if (!snapshot.exists) {
        throw Exception("Ride data not found.");
      }

      final rideData = RideRequestModel.fromMap(
        jsonDecode(jsonEncode(snapshot.value)) as Map<String, dynamic>,
      );

      // Update ride status in Firebase
      await RideRequestServicesDriver.updateRideRequestStatus(
        RideRequestServicesDriver.getRideStatus(3),
        rideID,
      );

      // Save ride to history (for both rider and driver)
      await Future.wait([
        riderHistoryRef.set(rideData.toMap()),
        driverHistoryRef.set(rideData.toMap()),
      ]);

      // Clean up
      await Future.wait([rideDataRef.remove(), driverActiveRef.remove()]);

      if (!context.mounted) return;

      ToastServices.sendScaffoldAlert(
        msg:
            'Trip Ended! You earned ${(int.parse(rideData.fare) * 0.9).toStringAsFixed(2)}',
        toastStatus: 'SUCCESS',
        context: context,
      );
    } catch (e, stack) {
      log('endRide error: $e\n$stack');
      if (context.mounted) {
        ToastServices.sendScaffoldAlert(
          msg: 'Failed to end ride. Please try again.',
          toastStatus: 'ERROR',
          context: context,
        );
      }
      throw Exception(e);
    }
  }
}
