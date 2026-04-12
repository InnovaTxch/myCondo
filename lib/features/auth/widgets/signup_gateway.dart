import 'package:flutter/material.dart';
import 'gateway_text.dart';

class SignupGateway extends StatelessWidget {
  const SignupGateway({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GatewayText(
          text: "Don't have an account yet? ", 
          textColor: Colors.black.withValues(alpha: 0.6)
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
          child: GatewayText(
            text: "Create an account",
            textColor: Color(0xFF53B1FD)
          ),
        )
      ],
    );
  }
}