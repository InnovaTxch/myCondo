import 'package:flutter/material.dart';
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
          textColor: Colors.black.withValues(alpha: 0.6),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
          child: GatewayText(
            text: "Sign up",
            textColor: Color(0xFF53B1FD),
          ),
        ),
      ],
    );
  }
}
