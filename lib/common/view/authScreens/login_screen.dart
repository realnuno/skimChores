import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:new_uber/common/controller/provider/auth_provider.dart';
import 'package:new_uber/common/controller/services/mobile_auth_services.dart';
import 'package:new_uber/common/widgets/asset_gen.dart';
import 'package:new_uber/common/widgets/or_divider.dart';
import 'package:new_uber/common/widgets/elevated_button_common.dart';
import 'package:new_uber/constant/utils/colors.dart';
import 'package:new_uber/constant/utils/textStyles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController mobileNumberController = TextEditingController();
  String selectedCountryCode = '+1';
  bool loginButtonPressed = false;
  List loginButtonData = [
    [const AssetGen().google.svg(height: 3.h), 'Google'],
    [const AssetGen().apple.svg(height: 3.h), 'Apple'],
    [const AssetGen().facebook.svg(height: 3.h), 'Facebook'],
    [const AssetGen().mail.svg(height: 3.h), 'Email'],
  ];

  login() {
    if (mobileNumberController.text.isNotEmpty) {
      setState(() {
        loginButtonPressed = true;
      });
      context.read<MobileAuthProvider>().updateMobileNumber(
        mobileNumberController.text.trim(),
      );
      MobileAuthServices.receiveOTP(
        context: context,
        mobileNumber:
            '$selectedCountryCode${mobileNumberController.text.trim()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
          children: [
            SizedBox(height: 1.h),
            Text(' Enter your mobile number', style: AppTextStyles.body18),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => {
                    showCountryPicker(
                      context: context,
                      onSelect: (value) {
                        setState(() {
                          selectedCountryCode = '+${value.phoneCode}';
                        });
                      },
                    ),
                  },
                  child: Container(
                    height: 6.h,
                    width: 20.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.sp),
                      color: greyShade2,
                      border: Border.all(color: grey),
                    ),
                    child: Text(selectedCountryCode),
                  ),
                ),
                SizedBox(
                  width: 70.w,
                  child: TextFormField(
                    controller: mobileNumberController,
                    cursorColor: black,
                    style: AppTextStyles.textFieldTextStyle,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 2.w,
                      ),
                      hintText: 'Mobile number',
                      hintStyle: AppTextStyles.textFieldHintTextStyle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.sp),
                        borderSide: BorderSide(color: grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.sp),
                        borderSide: BorderSide(color: grey),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.sp),
                        borderSide: BorderSide(color: grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.sp),
                        borderSide: BorderSide(color: grey),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            ElevatedButtonCommon(
              onPressed: () {
                login();
              },
              backgroundColor: black,
              height: 6.h,
              width: 94.w,
              child: loginButtonPressed == true
                  ? CircularProgressIndicator(color: white)
                  : Text(
                      'Continue',
                      style: AppTextStyles.small12Bold.copyWith(color: white),
                    ),
            ),
            SizedBox(height: 2.h),
            const OrDivider(),
            SizedBox(height: 2.h),
            ListView.builder(
              itemCount: loginButtonData.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Container(
                  height: 6.h,
                  width: 94.w,
                  margin: EdgeInsets.symmetric(vertical: 0.5.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.sp),
                    color: greyShade3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      loginButtonData[index][0],
                      SizedBox(width: 2.w),
                      Text('Continue with ${loginButtonData[index][1]}'),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 2.h),
            const OrDivider(),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.search, color: black),
                Text('Find my account', style: AppTextStyles.body14),
              ],
            ),
            SizedBox(height: 3.h),
            Text(
              'By proceeding, you consent to get calls, WhatsApp or SMS messages, including by automated means, from Uber and its affiliates to the number provided. ',
              style: AppTextStyles.small10.copyWith(color: grey),
            ),
            SizedBox(height: 15.h),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'This site is protected by reCAPTHA and the Google ',
                    style: AppTextStyles.small10.copyWith(color: grey),
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: AppTextStyles.small10.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(
                    text: ' and ',
                    style: AppTextStyles.small10.copyWith(color: grey),
                  ),
                  TextSpan(
                    text: 'Terms of Service',
                    style: AppTextStyles.small10.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(
                    text: ' apply',
                    style: AppTextStyles.small10.copyWith(color: grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
