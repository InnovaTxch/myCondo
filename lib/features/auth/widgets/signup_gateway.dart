import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'gateway_text.dart';

class SignupGateway extends StatelessWidget {
  const SignupGateway({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        GatewayText(
          text: "Need access to your condo? ",
          textColor: AppColors.secondaryText,
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
          child: GatewayText(
            text: "Sign up",
            textColor: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }
}
