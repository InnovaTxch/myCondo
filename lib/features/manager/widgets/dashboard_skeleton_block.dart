import 'package:flutter/material.dart';

class DashboardSkeletonBlock extends StatelessWidget {
  const DashboardSkeletonBlock({
    super.key,
    required this.width,
    required this.height,
    this.color = const Color(0xFFE3E1DC),
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
