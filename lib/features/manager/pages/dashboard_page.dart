import 'package:flutter/material.dart';

import 'package:mycondo/data/repositories/manager/manager_dashboard_service.dart';
import 'package:mycondo/data/models/manager/dashboard_models.dart';

import '../widgets/dashboard_announcement_section.dart';
import '../widgets/dashboard_defaults.dart';
import '../widgets/dashboard_greeting.dart';
import '../widgets/dashboard_navigation_bar.dart';
import '../widgets/dashboard_quick_action_tile.dart';
import '../widgets/dashboard_summary_card.dart';

class ManagerDashboardPage extends StatelessWidget {
  const ManagerDashboardPage({
    super.key,
    required this.managerName,
    required this.summary,
    required this.announcements,
    required this.quickActions,
    required this.navigationItems,
    required this.selectedNavigationIndex,
    this.onAddAnnouncement,
  });

  final String managerName;
  final DashboardSummary summary;
  final List<DashboardAnnouncement> announcements;
  final List<DashboardQuickAction> quickActions;
  final List<DashboardNavigationItem> navigationItems;
  final int selectedNavigationIndex;
  final VoidCallback? onAddAnnouncement;

  @override
  Widget build(BuildContext context) {
    final displayQuickActions =
        quickActions.isNotEmpty ? quickActions : defaultDashboardQuickActions;
    final displayNavigationItems = navigationItems.isNotEmpty
        ? navigationItems
        : defaultDashboardNavigationItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardGreeting(managerName: managerName),
              const SizedBox(height: 24),
              DashboardSummaryCard(summary: summary),
              const SizedBox(height: 16),
              DashboardAnnouncementSection(
                announcements: announcements,
                onAddAnnouncement: onAddAnnouncement,
              ),
              const SizedBox(height: 18),
              ...displayQuickActions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DashboardQuickActionTile(action: action),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardNavigationBar(
                            items: displayNavigationItems,
                            selectedIndex: selectedNavigationIndex,
      ),
    );
  }
}
