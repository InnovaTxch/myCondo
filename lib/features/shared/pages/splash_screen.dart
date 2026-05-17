import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
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

            // ✅ Expanded lets the image take remaining space without overflowing
            Expanded(
              child: Transform.translate(
                offset: Offset(-60, 0),
                child: Image.asset(
                  "assets/images/house.png",
                  fit: BoxFit.contain,
                ),
              ),
            ),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.pureWhite,
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
                    color: AppColors.pureWhite,
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
