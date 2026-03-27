import 'package:flutter/material.dart';

import 'package:mycondo/features/shared/pages/splash_screen.dart';
import 'package:mycondo/features/shared/pages/dashboard.dart';
import 'package:mycondo/features/auth/pages/role_selection.dart';
import 'package:mycondo/features/auth/pages/login_screen.dart';
import 'package:mycondo/features/auth/pages/signup_screen.dart';

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
        '/role': (context) => RoleSelection(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/dashboard': (context) => Dashboard(),
        '/add-bill': (context) => CreateBillPage()
      },
    );
  }
}