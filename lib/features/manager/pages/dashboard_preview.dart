import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/dashboard_models.dart';
import 'dashboard_page.dart';

void main() {
  runApp(const DashboardPreviewApp());
}

class DashboardPreviewApp extends StatelessWidget {
  const DashboardPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Manager Dashboard Preview',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF80BDF2)),
        useMaterial3: true,
        textTheme: GoogleFonts.urbanistTextTheme(),
        primaryTextTheme: GoogleFonts.urbanistTextTheme(),
      ),
      home: const ManagerDashboardPage(
        managerName: '',
        summary: DashboardSummary(
          totalTenants: null,
          pendingReports: null,
          paymentsToReview: null,
          completionPercent: null,
        ),
        announcements: [],
        quickActions: [],
        navigationItems: [],
        selectedNavigationIndex: 0,
      ),
    );
  }
}
