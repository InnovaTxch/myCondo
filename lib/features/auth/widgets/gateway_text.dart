import 'package:flutter/material.dart';

class GatewayText extends Text {
  GatewayText({
    super.key,
    required String text,
    required Color textColor,
  }) : super (
        text,
        style: TextStyle(
            fontFamily: "Urbanist",
            fontSize: 15,
            color: textColor
          ),
        );
}