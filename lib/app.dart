import 'package:flutter/material.dart';

import 'package:mycondo/features/manager/pages/manager_home_screen.dart';
import 'package:mycondo/features/manager/pages/manage_residents_page.dart';

import 'package:mycondo/features/auth/pages/login_screen.dart';
import 'package:mycondo/features/auth/pages/signup_screen.dart';
import 'package:mycondo/features/auth/pages/auth_gate.dart';

import 'package:mycondo/features/shared/pages/splash_screen.dart';
import 'package:mycondo/features/shared/pages/onboarding_page.dart';
import 'package:mycondo/features/resident/pages/resident_announcements_page.dart';
import 'package:mycondo/features/resident/pages/resident_bills_page.dart';
import 'package:mycondo/features/resident/pages/resident_home_screen.dart';

import 'package:mycondo/features/manager/pages/create_bill_page.dart';
import 'package:mycondo/features/manager/pages/announcements_page.dart';
import 'package:mycondo/features/manager/pages/approve_payments_screen.dart';

class MyCondoApp extends StatelessWidget {
  const MyCondoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'myCondo',
      debugShowCheckedModeBanner: false,

      initialRoute: '/',

      routes: {
        '/': (context) => const AuthGate(),
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/onboarding': (context) => const OnboardingPage(),
        '/manager-dashboard': (context) => const ManagerHomeScreen(),
        '/resident-dashboard': (context) => const ResidentHomeScreen(),
        '/resident-announcements': (context) =>
            const ResidentAnnouncementsPage(),
        '/resident-bills': (context) => const ResidentBillsPage(),
        '/manager-announcements': (context) => const ManagerAnnouncementsPage(),
        '/approve-payments': (context) => const ApprovePaymentsScreen(),
        '/manage-residents': (context) => const ManageResidentsPage(),
        '/add-bills': (context) => const CreateBillPage(),
      },
    );
  }
}
