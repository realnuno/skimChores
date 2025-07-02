import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:new_uber/common/controller/services/profile_data_crud_services.dart';
import 'package:new_uber/common/model/profile_data_model.dart';
import 'package:new_uber/constant/constants.dart';

class ProfileDataProvider extends ChangeNotifier {
  ProfileDataModel? profileData;

  getProfileData() async {
    profileData =
        await ProfileDataCRUDServices.getProfileDataFromRealTimeDatabase(
            auth.currentUser!.phoneNumber!);
    log(profileData!.toMap().toString());
    notifyListeners();
  }
}