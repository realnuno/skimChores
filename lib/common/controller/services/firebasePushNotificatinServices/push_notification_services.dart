import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:new_uber/common/controller/services/APIsNKeys/apis.dart';
import 'package:new_uber/common/controller/services/APIsNKeys/keys.dart';
import 'package:new_uber/common/controller/services/firebasePushNotificatinServices/push_notification_dialogue.dart';
import 'package:new_uber/common/model/profile_data_model.dart';
import 'package:new_uber/common/model/ride_request_model.dart';
import 'package:new_uber/constant/constants.dart';
import 'package:http/http.dart' as http;

class PushNotificationServices {
  //  Initializing Firebase Messaging Instance
  static FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  static Future initializeFirebaseMessaging(
    ProfileDataModel profileData,
    BuildContext context,
  ) async {
    await firebaseMessaging.requestPermission();
    if (profileData.userType == 'PARTNER') {
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackfroundHandlerDriver,
      );
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          firebaseMessagingForeGroundHandlerDriver(message, context);
        }
      });
    } else {
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackfroundHandlerRider,
      );
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          firebaseMessagingForeGroundHandlerRider(message);
        }
      });
    }
  }

  static String? getRideRequestID(RemoteMessage message) {
    return message.data['rideRequestID'];
  }
  // ! Rider Cloud Messaging Functions

  static Future<void> firebaseMessagingBackfroundHandlerRider(
    RemoteMessage message,
  ) async {}
  static Future<void> firebaseMessagingForeGroundHandlerRider(
    RemoteMessage message,
  ) async {}

  // ! Driver Cloud Messaging Functions
  static Future<void> firebaseMessagingBackfroundHandlerDriver(
    RemoteMessage message,
  ) async {
    String? riderID = getRideRequestID(message);
    // Handle null case if needed
  }

  static Future<void> firebaseMessagingForeGroundHandlerDriver(
    RemoteMessage message,
    BuildContext context,
  ) async {
    String? rideID = getRideRequestID(message);
    if (rideID != null) {
      await fetchRideRequestInfo(rideID, context);
    }
  }

  // ! *****************************************

  static Future getToken(ProfileDataModel model) async {
    String? token = await firebaseMessaging.getToken();
    log('Cloud Messaging Token is : $token');
    DatabaseReference tokenRef = FirebaseDatabase.instance.ref().child(
      'User/${auth.currentUser!.phoneNumber}/cloudMessagingToken',
    );
    tokenRef.set(token);
  }

  static Future<void> fetchRideRequestInfo(String rideID, BuildContext context) async {
    if (rideID.isEmpty) {
      return;
    }

    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref().child('RideRequest/$rideID');
      
      final databaseEvent = await ref.once();
      
      if (!context.mounted) return;
      
      if (databaseEvent.snapshot.exists && databaseEvent.snapshot.value != null) {
        RideRequestModel rideRequestModel = RideRequestModel.fromMap(
          jsonDecode(jsonEncode(databaseEvent.snapshot.value)) as Map<String, dynamic>,
        );
        
        if (!context.mounted) return;
        
        PushNotificationDialouge.rideRequestDialogue(rideRequestModel, context);
      }
    } catch (error) {
      // Silently handle errors
    }
  }

  static subscribeToNotification(ProfileDataModel model) {
    if (model.userType == 'PARTNER') {
      firebaseMessaging.subscribeToTopic('PARTNER');
      firebaseMessaging.subscribeToTopic('USER');
    } else {
      firebaseMessaging.subscribeToTopic('RIDER');
      firebaseMessaging.subscribeToTopic('USER');
    }
  }

  static initializeFirebaseMessagingForUsers(
    ProfileDataModel profileData,
    BuildContext context,
  ) {
    initializeFirebaseMessaging(profileData, context);
    getToken(profileData);
    subscribeToNotification(profileData);
  }

  static Future<void> sendRideRequestToNearbyDrivers(String driverFCMToken) async {
    try {
      final api = Uri.parse(APIs.pushNotificationAPI());
      final rideRequestID = auth.currentUser!.phoneNumber!;
      
      var body = jsonEncode({
        "to": driverFCMToken,
        "notification": {
          "body": "New Ride Request In your Location.",
          "title": "Ride Request",
        },
        "data": {"rideRequestID": rideRequestID},
      });
      
      await http
          .post(
            api,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'key=$fcmServerKey',
            },
            body: body,
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw TimeoutException('Connection Timed Out');
            },
          );
    } catch (e) {
      // Silently handle errors
    }
  }
}
