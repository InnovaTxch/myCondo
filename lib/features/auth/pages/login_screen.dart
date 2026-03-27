import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'tenant';

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
              "Welcome\nback!",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 30),

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
                Navigator.pushNamed(
                  context,
                  '/dashboard',
                  arguments: role,
                );
              },

              child: Text("Log in"),
            ),
          ],
        ),
      ),
    );
  }
}
