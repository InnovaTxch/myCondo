import 'package:flutter/material.dart';

import 'package:mycondo/features/auth/pages/auth_gate.dart';
import 'package:mycondo/features/auth/pages/login_screen.dart';
import 'package:mycondo/features/auth/pages/signup_screen.dart';

// Manager pages
import 'package:mycondo/features/manager/pages/announcements_page.dart';
import 'package:mycondo/features/manager/pages/approve_payments_screen.dart';
import 'package:mycondo/features/manager/pages/create_bill_page.dart';
import 'package:mycondo/features/manager/pages/dashboard_page.dart';
import 'package:mycondo/features/manager/pages/edit_profile_page.dart';
import 'package:mycondo/features/manager/pages/maintenance_requests_page.dart';
import 'package:mycondo/features/manager/pages/manage_condo_page.dart';
import 'package:mycondo/features/manager/pages/manage_residents_page.dart';
import 'package:mycondo/features/manager/pages/manager_bill_breakdown_page.dart';
import 'package:mycondo/features/manager/pages/manager_home_screen.dart';
import 'package:mycondo/features/manager/pages/manager_inbox_screen.dart';
import 'package:mycondo/features/manager/pages/manager_transaction_history_page.dart';
import 'package:mycondo/features/manager/pages/profile_page.dart';
import 'package:mycondo/features/manager/pages/resident_details_page.dart';
import 'package:mycondo/features/manager/pages/resident_form_page.dart';
import 'package:mycondo/features/manager/pages/unit_profile_page.dart';

// Resident pages
import 'package:mycondo/features/resident/pages/maintenance_request_form_page.dart';
import 'package:mycondo/features/resident/pages/maintenance_request_page.dart';
import 'package:mycondo/features/resident/pages/resident_announcements_page.dart';
import 'package:mycondo/features/resident/pages/resident_bill_breakdown_page.dart';
import 'package:mycondo/features/resident/pages/resident_bills_page.dart';
import 'package:mycondo/features/resident/pages/resident_dashboard.dart';
import 'package:mycondo/features/resident/pages/resident_home_screen.dart';
import 'package:mycondo/features/resident/pages/resident_manager_chat_screen.dart';
import 'package:mycondo/features/resident/pages/resident_profile_page.dart';
import 'package:mycondo/features/resident/pages/resident_unit_bill_page.dart';

// Shared pages
import 'package:mycondo/features/shared/pages/chat_screen.dart';
import 'package:mycondo/features/shared/pages/condo_about_page.dart';
import 'package:mycondo/features/shared/pages/onboarding_page.dart';
import 'package:mycondo/features/shared/pages/placeholder_page.dart';
import 'package:mycondo/features/shared/pages/splash_screen.dart';

// ignore_for_file: unused_import
// The imports above that have no corresponding named route below are still
// required here so that the Dart build system can compile a module summary
// for every library before it is needed at runtime (e.g. pages used as
// bottom-nav tabs or pushed via Navigator.push rather than named routes).

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    '/': (context) => const AuthGate(),
    '/splash': (context) => const SplashScreen(),
    '/login': (context) => const LoginScreen(),
    '/signup': (context) => const SignupScreen(),
    '/onboarding': (context) => const OnboardingPage(),

    // ── Manager ────────────────────────────────────────────────────────────
    '/manager-dashboard': (context) => const ManagerHomeScreen(),
    '/manager-announcements': (context) => const ManagerAnnouncementsPage(),
    '/manager-maintenance-requests': (context) =>
        const MaintenanceRequestsPage(),
    '/approve-payments': (context) => const ApprovePaymentsScreen(),
    '/manager-edit-profile': (context) => const ManagerEditProfilePage(),
    '/manage-condo': (context) => const ManageCondoPage(),
    '/manage-residents': (context) => const ManageResidentsPage(),
    '/add-bills': (context) => const CreateBillPage(),
    '/transaction-history': (context) => const ManagerTransactionHistoryPage(),
    '/manager-transactions': (context) => const ManagerTransactionHistoryPage(),

    // ── Resident ───────────────────────────────────────────────────────────
    '/resident-dashboard': (context) => const ResidentHomeScreen(),
    '/resident-announcements': (context) => const ResidentAnnouncementsPage(),
    '/resident-bills': (context) => const ResidentBillsPage(),
    '/resident-unit-bill': (context) => const ResidentUnitBillPage(),
    '/resident-bill-breakdown': (context) => const ResidentBillBreakdownPage(),
    '/resident-maintenance-request': (context) =>
        const MaintenanceRequestPage(),
    '/resident-maintenance-request-form': (context) =>
        const MaintenanceRequestFormPage(),
    '/resident-chat': (context) =>
        const ResidentManagerChatScreen(showBackButton: true),
  };
}