import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'gateway_text.dart';

class LoginGateway extends StatelessWidget {
  const LoginGateway({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GatewayText(
          text: "Already have an account? ", 
          textColor: AppColors.secondaryText
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          child: GatewayText(
            text: "Log in",
            textColor: AppColors.primaryBlue,
          ),
        )
      ],
    );
  }
}
