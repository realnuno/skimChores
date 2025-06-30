import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:new_uber/constant/utils/colors.dart';
import 'package:new_uber/constant/utils/textStyles.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: grey,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Text(
            'or',
            style: AppTextStyles.small12.copyWith(
              color: grey,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: grey,
          ),
        ),
      ],
    );
  }
}