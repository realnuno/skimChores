import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:new_uber/constant/constants.dart';
import 'package:new_uber/rider/view/bookARideScreen/book_a_ride_screen.dart';
import 'package:new_uber/rider/view/homeScreen/rider_home_screen.dart';

class RiderHomeScreeBuilder extends StatefulWidget {
  const RiderHomeScreeBuilder({super.key});

  @override
  State<RiderHomeScreeBuilder> createState() => _RiderHomeScreeBuilderState();
}

class _RiderHomeScreeBuilderState extends State<RiderHomeScreeBuilder> {
  DatabaseReference riderRideRequestRef = FirebaseDatabase.instance
      .ref()
      .child('RideRequest/${auth.currentUser!.phoneNumber}');
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: riderRideRequestRef.onValue,
        builder: (context, event) {
          if (event.connectionState == ConnectionState.waiting) {
            return const RiderHomeScreen();
          }
          if (event.data!.snapshot.value != null) {
            log('The Data is');
            log(event.data!.snapshot.value.toString());
            return const BookARideScreen();
          } else {
            return const RiderHomeScreen();
          }
        });
  }
}