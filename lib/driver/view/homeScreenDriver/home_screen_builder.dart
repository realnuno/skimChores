import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:new_uber/common/model/profile_data_model.dart';
import 'package:new_uber/constant/constants.dart';
import 'package:new_uber/driver/view/homeScreenDriver/driver_home_screen.dart';
import 'package:new_uber/driver/view/homeScreenDriver/trip_screen.dart';

class DriverHomeScreeBuilder extends StatefulWidget {
  const DriverHomeScreeBuilder({super.key});

  @override
  State<DriverHomeScreeBuilder> createState() => _DriverHomeScreeBuilderState();
}

class _DriverHomeScreeBuilderState extends State<DriverHomeScreeBuilder> {
  DatabaseReference driverProfileRef = FirebaseDatabase.instance
      .ref()
      .child('User/${auth.currentUser!.phoneNumber}');
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: driverProfileRef.onValue,
        builder: (context, event) {
          if (event.connectionState == ConnectionState.waiting) {
            return const HomeScreenDriver();
          }
          if (event.data != null) {
            ProfileDataModel profileData = ProfileDataModel.fromMap(
                jsonDecode(jsonEncode(event.data!.snapshot.value))
                    as Map<String, dynamic>);
            if (profileData.activeRideRequestID != null) {
              return  TripScreen(rideID:  profileData.activeRideRequestID!,);
            } else {
              return const HomeScreenDriver();
            }
          } else {
            return const HomeScreenDriver();
          }
        });
  }
}