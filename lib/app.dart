import 'package:flutter/material.dart';

import 'package:mycondo/features/manager/pages/dashboard_page.dart';
import 'package:mycondo/features/manager/pages/manage_residents_page.dart';

import 'package:mycondo/features/auth/pages/login_screen.dart';
import 'package:mycondo/features/auth/pages/signup_screen.dart';
import 'package:mycondo/data/repositories/auth/auth_gate.dart';

import 'package:mycondo/features/shared/pages/splash_screen.dart';
import 'package:mycondo/features/shared/pages/inbox_screen.dart';
import 'package:mycondo/features/shared/pages/onboarding_page.dart';
import 'package:mycondo/features/resident/pages/resident_home_screen.dart';

import 'package:mycondo/features/manager/pages/create_bill_page.dart';
import 'package:mycondo/features/manager/pages/announcements_page.dart';

class MyCondoApp extends StatelessWidget {
  const MyCondoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'myCondo',
      debugShowCheckedModeBanner: false,

      initialRoute: '/',

      routes: {
        '/': (context) => AuthGate(),
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/onboarding': (context) => OnboardingPage(),
        '/manager-dashboard': (context) => ManagerDashboardPage(),
        '/resident-dashboard': (context) => ResidentHomeScreen(),
        '/manager-transaction': (context) => ManagerDashboardPage(),
        '/manager-chat': (context) => InboxScreen(),
        '/manager-about': (context) => ManagerDashboardPage(),
        '/manager-profile': (context) => ManagerDashboardPage(),
        '/manager-announcements': (context) => ManagerAnnouncementsPage(),
        '/manage-residents': (context) => ManageResidentsPage(),
        '/add-bills': (context) => CreateBillPage()
      }
    );
  }
}
