import 'package:flutter/material.dart';

class ManagerDashboard extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Manager Dashboard")),

      body: Row(
        children: [

          Container(
            width: 250,
            color: Colors.grey[200],

            child: Column(
              children: [
                ListTile(title: Text("Residents")),
                ListTile(title: Text("Units")),
                ListTile(title: Text("Billing")),
                ListTile(title: Text("Announcements")),
              ],
            ),
          ),

          Expanded(
            child: Center(
              child: Text(
                "Manager Control Panel",
                style: TextStyle(
                  fontFamily: "Urbanist",
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}