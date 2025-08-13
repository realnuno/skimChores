// ignore_for_file: use_build_context_synchronously


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:new_uber/common/controller/provider/location_provider.dart';
import 'package:new_uber/common/controller/services/direction_services.dart';
import 'package:new_uber/common/controller/services/location_services.dart';
import 'package:new_uber/common/model/pickup_n_drop_location_model.dart';
import 'package:new_uber/common/model/searched_address_model.dart';
import 'package:new_uber/constant/utils/colors.dart';
import 'package:new_uber/constant/utils/textStyles.dart';
import 'package:new_uber/rider/controller/provider/tripProvider/ride_request_provider.dart';
import 'package:new_uber/rider/view/bookARideScreen/book_a_ride_screen.dart';

class PickupAndDropLocationScreen extends StatefulWidget {
  const PickupAndDropLocationScreen({super.key});

  @override
  State<PickupAndDropLocationScreen> createState() =>
      _PickupAndDropLocationScreenState();
}

class _PickupAndDropLocationScreenState
    extends State<PickupAndDropLocationScreen> {
  TextEditingController pickupLocationController = TextEditingController();
  TextEditingController dropLocationController = TextEditingController();
  FocusNode dropLocationFocus = FocusNode();
  FocusNode pickupLocationFocus = FocusNode();
  String locationType = 'DROP';
  bool isNavigating = false; // Add this to prevent multiple navigation calls

  getCurrentAddress() async {
    LatLng? crrLocation = await LocationServices.getCurrentLocation();
    if (crrLocation == null) {
      // Handle case where location permission is denied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied. Please enable location services.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    PickupNDropLocationModel currentLocationAddress =
        await LocationServices.getAddressFromLatLng(
          position: crrLocation,
          context: context,
        );
    pickupLocationController.text = currentLocationAddress.name!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getCurrentAddress();
      context.read<RideRequestProvider>().createIcons(context);
      FocusScope.of(context).requestFocus(dropLocationFocus);
    });
  }

  navigateToBookRideScreen() async {
    print('🚀 navigateToBookRideScreen called');
    
    // Prevent multiple simultaneous calls
    if (isNavigating) {
      print('⚠️ Navigation already in progress, returning early');
      return;
    }
    isNavigating = true;
    
    try {
      print('📍 Checking location data...');
      if (context.read<LocationProvider>().pickupLocation != null &&
          context.read<LocationProvider>().dropLocation != null) {
        
        // Additional validation to ensure coordinates are valid
        final pickup = context.read<LocationProvider>().pickupLocation!;
        final drop = context.read<LocationProvider>().dropLocation!;
        
        print('📍 Pickup: ${pickup.latitude}, ${pickup.longitude}');
        print('📍 Drop: ${drop.latitude}, ${drop.longitude}');
        
        if (pickup.latitude == null || pickup.longitude == null ||
            drop.latitude == null || drop.longitude == null) {
          print('❌ Invalid location data detected');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid location data. Please try selecting locations again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        print('✅ Location data valid, proceeding with navigation...');
        
        context.read<RideRequestProvider>().updateRidePickupAndDropLocation(
          pickup,
          drop,
        );
        
        LatLng pickupLocation = LatLng(
          pickup.latitude!,
          pickup.longitude!,
        );
        LatLng dropLocation = LatLng(drop.latitude!, drop.longitude!);
        
        print('🗺️ Getting directions...');
        await DirectionServices.getDirectionDetailsRider(
          pickupLocation,
          dropLocation,
          context,
        );
        
        print('💰 Calculating fare...');
        context.read<RideRequestProvider>().makeFareZero();
        context.read<RideRequestProvider>().createIcons(context);
        context.read<RideRequestProvider>().updateMarker();
        context.read<RideRequestProvider>().getFare();
        context
            .read<RideRequestProvider>()
            .decodePolylineAndUpdatePolylineField();
        
        print('🚀 Navigating to BookARideScreen...');
        Navigator.push(
          context,
          PageTransition(
            child: const BookARideScreen(),
            type: PageTransitionType.rightToLeft,
          ),
        );
        print('✅ Navigation completed successfully');
      } else {
        print('❌ Missing location data');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select both pickup and drop locations.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error during navigation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isNavigating = false;
      print('🔄 Navigation flag reset');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size(100.w, 25.h),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back, size: 4.h, color: black),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        child: Column(
                          children: [
                            Icon(Icons.circle, size: 2.h, color: black),
                            Container(
                              width: 1.w,
                              height: 6.h,
                              color: black,
                              margin: EdgeInsets.symmetric(vertical: 0.5.h),
                            ),
                            Icon(Icons.square, size: 2.h, color: black),
                          ],
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: pickupLocationController,
                              focusNode: pickupLocationFocus,
                              cursorColor: black,
                              style: AppTextStyles.textFieldTextStyle,
                              keyboardType: TextInputType.name,
                              onChanged: (value) {
                                setState(() {
                                  locationType = 'PICKUP';
                                });
                                LocationServices.getSearchedAddress(
                                  placeName: value,
                                  context: context,
                                );
                              },
                              decoration: InputDecoration(
                                suffixIcon: InkWell(
                                  onTap: () {
                                    context
                                        .read<LocationProvider>()
                                        .nullifyPickupLocation();
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(pickupLocationFocus);
                                    pickupLocationController.clear();
                                  },
                                  child: Icon(
                                    CupertinoIcons.xmark,
                                    color: black38,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 1.5.h,
                                  horizontal: 2.w,
                                ),
                                hintText: 'Pickup Address',
                                hintStyle: AppTextStyles.textFieldHintTextStyle,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.sp),
                                  borderSide: BorderSide(color: grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.sp),
                                  borderSide: BorderSide(color: grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.sp),
                                  borderSide: BorderSide(color: grey),
                                ),
                              ),
                            ),
                            SizedBox(height: 1.h),
                            TextFormField(
                              controller: dropLocationController,
                              focusNode: dropLocationFocus,
                              cursorColor: black,
                              style: AppTextStyles.textFieldTextStyle,
                              keyboardType: TextInputType.name,
                              onChanged: (value) {
                                setState(() {
                                  locationType = 'DROP';
                                });
                                LocationServices.getSearchedAddress(
                                  placeName: value,
                                  context: context,
                                );
                              },
                              decoration: InputDecoration(
                                suffixIcon: InkWell(
                                  onTap: () {
                                    context
                                        .read<LocationProvider>()
                                        .nullifyDropLocation();
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(dropLocationFocus);
                                    dropLocationController.clear();
                                  },
                                  child: Icon(
                                    CupertinoIcons.xmark,
                                    color: black38,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 1.5.h,
                                  horizontal: 2.w,
                                ),
                                hintText: 'Drop Address',
                                hintStyle: AppTextStyles.textFieldHintTextStyle,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.sp),
                                  borderSide: BorderSide(color: grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.sp),
                                  borderSide: BorderSide(color: grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.sp),
                                  borderSide: BorderSide(color: grey),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Consumer<LocationProvider>(
          builder: (context, locationProvider, child) {
            if (locationProvider.searchedAddress.isEmpty) {
              return Center(
                child: Text('Search Address', style: AppTextStyles.small12),
              );
            } else {
              return ListView.builder(
                itemCount: locationProvider.searchedAddress.length,
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  SearchedAddressModel currentAddress =
                      locationProvider.searchedAddress[index];
                  return ListTile(
                    onTap: () async {
                      if (locationType == 'DROP') {
                        dropLocationController.text = currentAddress.mainName;
                      } else {
                        pickupLocationController.text = currentAddress.mainName;
                      }
                      await LocationServices.getLatLngFromPlaceID(
                        currentAddress,
                        context,
                        locationType,
                      );
                      navigateToBookRideScreen();
                    },
                    leading: CircleAvatar(
                      backgroundColor: greyShade3,
                      radius: 3.h,
                      child: Icon(Icons.location_on, color: black),
                    ),
                    title: Text(
                      currentAddress.mainName,
                      style: AppTextStyles.small12Bold,
                    ),
                    subtitle: Text(
                      currentAddress.mainName,
                      style: AppTextStyles.small10.copyWith(color: grey),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}