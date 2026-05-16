import 'package:flutter/material.dart';

class BadgedNavigationIcon extends StatelessWidget {
  const BadgedNavigationIcon({
    super.key,
    required this.icon,
    this.showBadge = false,
  });

  final IconData icon;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (showBadge)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}