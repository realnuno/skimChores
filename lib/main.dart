import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
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

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: 'SkimChores',
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // ✅ Use debug for development
    // androidProvider: AndroidProvider.playIntegrity, // ← use for production
  );

  runApp(const Uber());
}

class Uber extends StatefulWidget {
  const Uber({super.key});

  @override
  State<Uber> createState() => _UberState();
}

class _UberState extends State<Uber> {
  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, _, __) {
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
            appBarTheme: AppBarTheme(
              color: white,
              elevation: 0,
            ),
          ),
          home: const SignInLogic(),
        ),
      );
      // return
    });
  }
}