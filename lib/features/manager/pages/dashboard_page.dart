import 'package:flutter/material.dart';

import 'package:mycondo/data/repositories/manager/manager_dashboard_service.dart';
import 'package:mycondo/data/models/manager/dashboard_models.dart';

import '../widgets/dashboard_announcement_section.dart';
import '../widgets/dashboard_greeting.dart';
import '../widgets/dashboard_navigation_bar.dart';
import '../widgets/dashboard_summary_card.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_quick_action_tile.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPage();
}

class _ManagerDashboardPage extends State<ManagerDashboardPage> {

  ManagerDashboardService dashboardService = ManagerDashboardService();

  String? managerName;
  DashboardSummary summary = DashboardSummary();
  List<DashboardAnnouncement> announcements = [];
  List<DashboardQuickAction> quickActions = [];
  int selectedNavigationIndex = 0;
  VoidCallback? onAddAnnouncement;

  Future<void> _initializePage() async{
    final name = await dashboardService.getFirstName();

    if (!mounted) return;
    setState(() {
      managerName = name;

    });
  }

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardGreeting(managerName: managerName ?? ""),
              const SizedBox(height: 24),
              DashboardSummaryCard(summary: summary),
              const SizedBox(height: 16),
              DashboardAnnouncementSection(
                announcements: announcements,
                onAddAnnouncement: onAddAnnouncement,
              ),
              const SizedBox(height: 18),
            
              DashboardQuickActions(),
              
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardNavigationBar(),
    );
  }
}
