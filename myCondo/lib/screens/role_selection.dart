import 'package:flutter/material.dart';

class RoleSelection extends StatelessWidget {

  void chooseRole(BuildContext context, String role) {
    Navigator.pushNamed(context, '/signup');
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Color(0xFFF4F4F4),

      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            SizedBox(height: 120),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Text(
                  "Choose\nyour role:",
                  style: TextStyle(
                    fontFamily: "Urbanist",
                    fontSize: 50,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),



                Icon(
                  Icons.apartment,
                  size: 60,
                ),
              ],
            ),

            SizedBox(height: 80),

            Center(
              child: Column(
                children: [

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: Size(260, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(color: Colors.black),
                      ),
                    ),

                    onPressed: () {
                      chooseRole(context, "manager");
                    },

                    child: Text("Manager"),
                  ),

                  SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: Size(260, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(color: Colors.black),
                      ),
                    ),

                    onPressed: () {
                      chooseRole(context, "tenant");
                    },

                    child: Text("Tenant"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}