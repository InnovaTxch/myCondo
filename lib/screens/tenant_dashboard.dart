import 'package:flutter/material.dart';

class TenantDashboard extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Tenant Dashboard")),

      body: Center(
        child: Text(
          "Mobile Tenant Interface",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}