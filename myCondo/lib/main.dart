import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/role_selection.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard.dart';

void main() {
  runApp(MyCondoApp());
}

class MyCondoApp extends StatelessWidget {
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
      },
    );
  }
}