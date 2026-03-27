import 'package:flutter/material.dart';

class ResidentDashboard extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Resident Dashboard")),

      body: Center(
        child: Text(
          "Mobile Resident Interface",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}