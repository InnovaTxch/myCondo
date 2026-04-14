import 'package:flutter/material.dart';


class ResidentDashboard extends StatelessWidget {
  const ResidentDashboard({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: Text(
          "RESIDENT DASHBOARD",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
