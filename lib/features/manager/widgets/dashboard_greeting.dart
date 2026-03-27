import 'package:flutter/material.dart';

import 'dashboard_skeleton_block.dart';

class DashboardGreeting extends StatelessWidget {
  const DashboardGreeting({
    super.key,
    required this.managerName,
  });

  final String managerName;

  @override
  Widget build(BuildContext context) {
    final hasManagerName = managerName.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                height: 1.1,
              ),
        ),
        const SizedBox(height: 2),
        if (hasManagerName)
          Text(
            managerName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  height: 1.05,
                ),
          )
        else
          const DashboardSkeletonBlock(
            width: 170,
            height: 26,
            color: Color(0xFFD9D7D1),
          ),
      ],
    );
  }
}
