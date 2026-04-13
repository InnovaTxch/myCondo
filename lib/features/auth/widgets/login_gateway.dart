import 'package:flutter/material.dart';
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
          textColor: Colors.black.withValues(alpha: 0.6)
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          child: GatewayText(
            text: "Log in",
            textColor: Color(0xFF53B1FD)
          ),
        )
      ],
    );
  }
}