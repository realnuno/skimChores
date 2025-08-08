import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:new_uber/driver/controller/provider/location_provider_driver.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:new_uber/common/controller/provider/auth_provider.dart';
import 'package:new_uber/common/controller/provider/location_provider.dart';
import 'package:new_uber/common/controller/provider/profile_data_provider.dart';
import 'package:new_uber/common/view/signInLogic/sign_in_logic.dart';
import 'package:new_uber/constant/utils/colors.dart';
import 'package:new_uber/driver/controller/provider/ride_request_provider.dart';
import 'package:new_uber/driver/controller/services/bottom_nav_bar_driver_provider.dart';
import 'package:new_uber/driver/controller/services/maps_provider_driver.dart';
import 'package:new_uber/firebase_options.dart';
import 'package:new_uber/rider/controller/provider/bottomNavBarRiderProvider/bottom_nav_bar_rider_provider.dart';
import 'package:new_uber/rider/controller/provider/tripProvider/ride_request_provider.dart';

// Global background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
}

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      name: 'SkimChores',
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request notification permissions
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      String? token = await messaging.getToken();
      print('FCM Token: $token');
    } else {
      print('User declined or has not accepted permission');
    }

    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug, // ✅ Use debug for development
      // androidProvider: AndroidProvider.playIntegrity, // ← use for production
    );

    runApp(const Uber());
  } catch (e) {
    print('Error initializing Firebase: $e');
    // You might want to show an error screen here
    runApp(const Uber());
  }
}

class Uber extends StatefulWidget {
  const Uber({super.key});

  @override
  State<Uber> createState() => _UberState();
}

class _UberState extends State<Uber> {
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, _, __) {
        return MultiProvider(
          providers: [
            // ! Common Providers
            ChangeNotifierProvider<MobileAuthProvider>(
              create: (_) => MobileAuthProvider(),
            ),
            ChangeNotifierProvider<LocationProvider>(
              create: (_) => LocationProvider(),
            ),
            ChangeNotifierProvider<LocationProviderDriver>(
              create: (_) => LocationProviderDriver(),
            ),
            ChangeNotifierProvider<ProfileDataProvider>(
              create: (_) => ProfileDataProvider(),
            ),
            // ! Rider Providers
            ChangeNotifierProvider<BottomNavBarRiderProvider>(
              create: (_) => BottomNavBarRiderProvider(),
            ),
            ChangeNotifierProvider<RideRequestProvider>(
              create: (_) => RideRequestProvider(),
            ),
            // ! Driver Providers
            ChangeNotifierProvider<BottomNavBarDriverProvider>(
              create: (_) => BottomNavBarDriverProvider(),
            ),
            ChangeNotifierProvider<MapsProviderDriver>(
              create: (_) => MapsProviderDriver(),
            ),
            ChangeNotifierProvider<RideRequestProviderDriver>(
              create: (_) => RideRequestProviderDriver(),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              appBarTheme: AppBarTheme(color: white, elevation: 0),
            ),
            home: const SignInLogic(),
          ),
        );
        // return
      },
    );
  }
}
