// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:new_uber/common/controller/provider/location_provider.dart';
import 'package:new_uber/common/controller/services/APIsNKeys/apis.dart';
import 'package:http/http.dart' as http;
import 'package:new_uber/common/controller/services/toast_services.dart';
import 'package:new_uber/common/model/pickup_n_drop_location_model.dart';
import 'package:new_uber/common/model/searched_address_model.dart';

class LocationServices {
  static getCurrentLocation() async {
    print('📍 getCurrentLocation called');
    
    LocationPermission permission = await Geolocator.checkPermission();
    print('🔐 Current permission status: $permission');
    
    if (permission == LocationPermission.denied) {
      print('⚠️ Permission denied, requesting permission...');
      permission = await Geolocator.requestPermission();
      print('🔐 New permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        print('❌ Permission still denied, returning null');
        return null; // Return null instead of recursive call
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      print('❌ Permission denied forever, returning null');
      return null;
    }
    
    print('✅ Permission granted, getting current position...');
    
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      
      print('📍 Position obtained: ${currentPosition.latitude}, ${currentPosition.longitude}');
      
      LatLng currentLocation = LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      
      print('✅ Returning location: ${currentLocation.latitude}, ${currentLocation.longitude}');
      return currentLocation;
    } catch (e) {
      print('❌ Error getting position: $e');
      return null;
    }
  }

  static Future getAddressFromLatLng({
    required LatLng position,
    required BuildContext context,
  }) async {
    final api = Uri.parse(APIs.geoCoadingAPI(position));
    try {
      var response = await http
          .get(api, headers: {'Content-Type': 'application/json'})
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              if (!context.mounted) return Future.error(TimeoutException('Connection Timed Out'));
              ToastServices.sendScaffoldAlert(
                msg: 'Opps! Connection Timed Out',
                toastStatus: 'ERROR',
                context: context,
              );
              throw TimeoutException('Connection Timed Out');
            },
          );

      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(response.body);
        PickupNDropLocationModel model = PickupNDropLocationModel(
          name: decodedResponse['results'][0]['formatted_address'],
          placeID: decodedResponse['results'][0]['place_id'],
          latitude: position.latitude,
          longitude: position.longitude, // Fixed: was position.latitude
        );
        log(model.toMap().toString());
        context.read<LocationProvider>().updatePickupLocation(model);
        return model;
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  static Future getSearchedAddress({
    required String placeName,
    required BuildContext context,
  }) async {
    List<SearchedAddressModel> address = [];
    final api = Uri.parse(APIs.placesAPI(placeName));
    try {
      var response = await http
          .get(api, headers: {'Content-Type': 'application/json'})
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              if (!context.mounted) throw TimeoutException('Connection Timed Out');
              ToastServices.sendScaffoldAlert(
                msg: 'Opps! Connection Timed Out',
                toastStatus: 'ERROR',
                context: context,
              );
              throw TimeoutException('Connection Timed Out');
            },
          );

      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(response.body);
        for (var data in decodedResponse['predictions']) {
          address.add(
            SearchedAddressModel(
              mainName: data['structured_formatting']['main_text'],
              secondaryName: data['structured_formatting']['secondary_text'],
              placeID: data['place_id'],
            ),
          );
        }
        context.read<LocationProvider>().updateSearchedAddress(address);
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  static getLatLngFromPlaceID(
    SearchedAddressModel address,
    BuildContext context,
    String locationType,
  ) async {
    print('🔍 getLatLngFromPlaceID called for: ${address.mainName} ($locationType)');
    
    final api = Uri.parse(APIs.getLatLngFromPlaceIDAPI(address.placeID));

    try {
      print('🌐 Making API request to: ${api.toString().substring(0, 100)}...');
      
      var response = await http
          .get(api, headers: {'Content-Type': 'application/json'})
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              if (!context.mounted) throw TimeoutException('Connection Timed Out');
              ToastServices.sendScaffoldAlert(
                msg: 'Opps! Connection Timed Out',
                toastStatus: 'ERROR',
                context: context,
              );
              throw TimeoutException('Connection Timed Out');
            },
          );
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(response.body);
        print('📋 Response decoded successfully');

        var locationLatLng = decodedResponse['result']['geometry']['location'];
        print('📍 Location data: $locationLatLng');
        
        PickupNDropLocationModel model = PickupNDropLocationModel(
          name: address.mainName,
          description: address.secondaryName,
          placeID: address.placeID,
          latitude: locationLatLng['lat'],
          longitude: locationLatLng['lng'],
        );

        print('✅ Created location model: ${model.toMap()}');

        if (locationType == 'DROP') {
          print('📍 Updating drop location');
          context.read<LocationProvider>().updateDropLocation(model);
        } else {
          print('📍 Updating pickup location');
          context.read<LocationProvider>().updatePickupLocation(model);
        }
        
        print('✅ Location updated successfully');
      } else {
        print('❌ API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getLatLngFromPlaceID: $e');
      throw Exception(e);
    }
  }
}
