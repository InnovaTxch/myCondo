import 'package:flutter/material.dart';

import 'package:mycondo/features/auth/pages/auth_gate.dart';
import 'package:mycondo/features/auth/pages/login_screen.dart';
import 'package:mycondo/features/auth/pages/signup_screen.dart';
import 'package:mycondo/features/manager/pages/announcements_page.dart';
import 'package:mycondo/features/manager/pages/approve_payments_screen.dart';
import 'package:mycondo/features/manager/pages/create_bill_page.dart';
import 'package:mycondo/features/manager/pages/edit_profile_page.dart';
import 'package:mycondo/features/manager/pages/manage_condo_page.dart';
import 'package:mycondo/features/manager/pages/maintenance_requests_page.dart';
import 'package:mycondo/features/manager/pages/manage_residents_page.dart';
import 'package:mycondo/features/manager/pages/manager_home_screen.dart';
import 'package:mycondo/features/resident/pages/maintenance_request_form_page.dart';
import 'package:mycondo/features/resident/pages/maintenance_request_page.dart';
import 'package:mycondo/features/resident/pages/resident_announcements_page.dart';
import 'package:mycondo/features/resident/pages/resident_bill_breakdown_page.dart';
import 'package:mycondo/features/resident/pages/resident_bills_page.dart';
import 'package:mycondo/features/resident/pages/resident_home_screen.dart';
import 'package:mycondo/features/resident/pages/resident_unit_bill_page.dart';
import 'package:mycondo/features/shared/pages/onboarding_page.dart';
import 'package:mycondo/features/shared/pages/splash_screen.dart';
import 'package:mycondo/features/manager/pages/manager_transaction_history_page.dart';

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    '/': (context) => const AuthGate(),
    '/splash': (context) => const SplashScreen(),
    '/login': (context) => const LoginScreen(),
    '/signup': (context) => const SignupScreen(),
    '/onboarding': (context) => const OnboardingPage(),
    '/manager-dashboard': (context) => const ManagerHomeScreen(),
    '/resident-dashboard': (context) => const ResidentHomeScreen(),
    '/resident-announcements': (context) => const ResidentAnnouncementsPage(),
    '/resident-bills': (context) => const ResidentBillsPage(),
    '/resident-unit-bill': (context) => const ResidentUnitBillPage(),
    '/resident-bill-breakdown': (context) => const ResidentBillBreakdownPage(),
    '/resident-maintenance-request': (context) =>
        const MaintenanceRequestPage(),
    '/resident-maintenance-request-form': (context) =>
        const MaintenanceRequestFormPage(),
    '/manager-announcements': (context) => const ManagerAnnouncementsPage(),
    '/approve-payments': (context) => const ApprovePaymentsScreen(),
    '/manager-edit-profile': (context) => const ManagerEditProfilePage(),
    '/manage-condo': (context) => const ManageCondoPage(),
    '/manage-residents': (context) => const ManageResidentsPage(),
    '/manager-maintenance-requests': (context) =>
        const MaintenanceRequestsPage(),
    '/add-bills': (context) => const CreateBillPage(),
    '/transaction-history': (context) => const ManagerTransactionHistoryPage(),
    '/manager-transactions': (context) => const ManagerTransactionHistoryPage(),
  };
}
