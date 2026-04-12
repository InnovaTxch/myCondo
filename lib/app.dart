import 'package:flutter/material.dart';

import 'package:mycondo/features/shared/pages/splash_screen.dart';
import 'package:mycondo/features/manager/pages/dashboard_page.dart';
import 'package:mycondo/features/manager/widgets/dashboard_models.dart';
import 'package:mycondo/features/auth/pages/login_screen.dart';
import 'package:mycondo/features/auth/pages/signup_screen.dart';
import 'package:mycondo/features/shared/pages/onboarding_page.dart';

import 'package:mycondo/features/manager/pages/create_bill_page.dart';

class MyCondoApp extends StatelessWidget {
  const MyCondoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'myCondo',
      debugShowCheckedModeBanner: false,

      initialRoute: '/',

      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/manager-dashboard': (context) => ManagerDashboardPage(),
        '/manager-profile': (context) => ManagerDashboardPage(),
        '/add-bill': (context) => CreateBillPage()
      }
    );
  }
}
