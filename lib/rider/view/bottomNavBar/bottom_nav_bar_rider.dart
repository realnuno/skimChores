// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:new_uber/rider/view/homeScreen/rider_home_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:new_uber/common/controller/services/firebasePushNotificatinServices/push_notification_services.dart';
import 'package:new_uber/common/controller/services/profile_data_crud_services.dart';
import 'package:new_uber/common/model/profile_data_model.dart';
import 'package:new_uber/constant/constants.dart';
import 'package:new_uber/constant/utils/colors.dart';
import 'package:new_uber/rider/controller/provider/bottomNavBarRiderProvider/bottom_nav_bar_rider_provider.dart';
import 'package:new_uber/rider/view/account/account_screen_rider.dart';
import 'package:new_uber/rider/view/activity/activity_screen.dart';
import 'package:new_uber/rider/view/serviceScreen/service_screen.dart';

class BottomNavBarRider extends StatefulWidget {
  const BottomNavBarRider({super.key});

  @override
  State<BottomNavBarRider> createState() => _BottomNavBarRiderState();
}

class _BottomNavBarRiderState extends State<BottomNavBarRider> {
  List<Widget> screens = [
    const RiderHomeScreen(),
    const ServiceScreenRider(),
    const ActivityScreenRider(),
    const AccountScreenRider(),
  ];

  List<PersistentBottomNavBarItem> _navBarItems(int currentTab) {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(
            currentTab == 0 ? CupertinoIcons.house_fill : CupertinoIcons.house),
        title: 'Home',
        activeColorPrimary: black,
        inactiveColorPrimary: grey,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(currentTab == 0
            ? CupertinoIcons.circle_grid_3x3_fill
            : CupertinoIcons.circle_grid_3x3),
        title: 'Services',
        activeColorPrimary: black,
        inactiveColorPrimary: grey,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(currentTab == 0
            ? CupertinoIcons.square_list_fill
            : CupertinoIcons.square_list),
        title: 'Activity',
        activeColorPrimary: black,
        inactiveColorPrimary: grey,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(currentTab == 0
            ? CupertinoIcons.person_fill
            : CupertinoIcons.person),
        title: 'Account',
        activeColorPrimary: black,
        inactiveColorPrimary: grey,
      ),
    ];
  }

  PersistentTabController controller = PersistentTabController(initialIndex: 0);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ProfileDataModel profileData =
          await ProfileDataCRUDServices.getProfileDataFromRealTimeDatabase(
              auth.currentUser!.phoneNumber!);
      PushNotificationServices.initializeFirebaseMessagingForUsers(
          profileData, context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BottomNavBarRiderProvider>(
        builder: (context, tabProvider, child) {
      return PersistentTabView(
        context,
        screens: screens,
        controller: controller,
        items: _navBarItems(tabProvider.currentTab),
        confineInSafeArea: true,
        onItemSelected: (value) {},
        backgroundColor: white,
        handleAndroidBackButtonPress: true,
        resizeToAvoidBottomInset: true,
        stateManagement: false,
        hideNavigationBarWhenKeyboardShows: true,
        decoration: NavBarDecoration(
          borderRadius: BorderRadius.circular(8.sp),
          colorBehindNavBar: white,
        ),
        popAllScreensOnTapOfSelectedTab: true,
        popActionScreens: PopActionScreensType.all,
        itemAnimationProperties: const ItemAnimationProperties(
            duration: Duration(milliseconds: 200), curve: Curves.ease),
        screenTransitionAnimation: const ScreenTransitionAnimation(
          animateTabTransition: true,
          curve: Curves.ease,
          duration: Duration(milliseconds: 200),
        ),
        navBarStyle: NavBarStyle.style6,
      );
    });
  }
}