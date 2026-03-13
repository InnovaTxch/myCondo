import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {

  final Widget mobile;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {

    double width = MediaQuery.of(context).size.width;

    if (width > 800) {
      return desktop;
    } else {
      return mobile;
    }
  }
}