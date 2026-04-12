import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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

            Text(
              "Manage\nyour home",
              style: TextStyle(
                fontFamily: "Urbanist",
                fontSize: 50,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),

            SizedBox(height: 5),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "away from home",
              style: TextStyle(
                fontFamily: "Urbanist",
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          Transform.translate(
            offset: Offset(-60, 0), // move left
            child: Image.asset(
              "assets/images/house.png",
              height: 500,
              fit: BoxFit.contain,
            ),
          ),


            Spacer(),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: Size(300, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),

                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },

                child: Text(
                  "Let's Get Started",
                  style: TextStyle(
                    fontFamily: "Urbanist",
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
