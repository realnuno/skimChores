import 'package:flutter/material.dart';
import 'package:new_uber/common/controller/services/mobile_auth_services.dart';
import 'package:new_uber/constant/utils/colors.dart';

class SignInLogic extends StatefulWidget {
  const SignInLogic({super.key});

  @override
  State<SignInLogic> createState() => _SignInLogicState();
}

class _SignInLogicState extends State<SignInLogic> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await MobileAuthServices.checkAuthenticationAndNavigate(context: context);
    });
  }



  

  @override
  Widget build(BuildContext context) {
    Scaffold(
      backgroundColor: black,
      body: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    return Scaffold(backgroundColor: black,
      body: const Center(
        child: Image(image: AssetImage('assets/images/uberLogo/uber.png')),
      ),
    );
  }
}