import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {

  Widget inputField(String hint) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),

      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Color(0xFFF4F4F4),

      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),

        child: ListView(
          children: [

            SizedBox(height: 60),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("< Back"),
            ),

            SizedBox(height: 10),

            Text(
              "Create an\naccount.",
              style: TextStyle(
                fontFamily: "Urbanist",
                fontSize: 45,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),



            SizedBox(height: 30),

            inputField("Full Name"),
            inputField("Contact Number"),
            inputField("Email"),
            inputField("Password"),


            SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5DA9E9),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),

              onPressed: () {
                Navigator.pushNamed(context, '/dashboard');
              },

              child:
                Text(
                  "Sign up",
                  style: TextStyle(
                    fontFamily: "Urbanist",
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }
}