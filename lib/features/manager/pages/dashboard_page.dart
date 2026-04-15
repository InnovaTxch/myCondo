import 'package:flutter/material.dart';

import 'package:mycondo/data/models/manager/announcement_models.dart';
import 'package:mycondo/data/repositories/manager/manager_dashboard_service.dart';
import 'package:mycondo/data/repositories/manager/manager_announcement_service.dart';
import 'package:mycondo/data/models/manager/dashboard_models.dart';

import '../widgets/dashboard_announcement_section.dart';
import '../widgets/dashboard_greeting.dart';
import '../widgets/dashboard_navigation_bar.dart';
import '../widgets/dashboard_summary_card.dart';
import '../widgets/dashboard_quick_actions.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPage();
}

class _ManagerDashboardPage extends State<ManagerDashboardPage> {

  ManagerDashboardService dashboardService = ManagerDashboardService();
  ManagerAnnouncementService announcementService = ManagerAnnouncementService();

  String? managerName;
  DashboardSummary summary = DashboardSummary();
  DashboardAnnouncement? highlightedAnnouncement;
  bool isAnnouncementLoading = true;
  int selectedNavigationIndex = 0;

  Future<void> _initializePage() async {
    try {
      final results = await Future.wait([
        dashboardService.getFirstName(),
        announcementService.getAnnouncements(),
      ]);

      final name = results[0] as String?;
      final announcements = results[1] as List<Announcement>;

      if (!mounted) return;
      setState(() {
        managerName = name;
        highlightedAnnouncement = _toHighlightedAnnouncement(announcements);
        isAnnouncementLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isAnnouncementLoading = false;
      });
    }
  }

  DashboardAnnouncement? _toHighlightedAnnouncement(List<Announcement> announcements) {
    if (announcements.isEmpty) return null;

    Announcement selected = announcements.first;
    for (final ann in announcements) {
      if (ann.category == 'urgent') {
        selected = ann;
        break;
      }
      if (ann.category == 'reminder' && selected.category != 'urgent') {
        selected = ann;
      }
    }

    final colorScheme = _categoryStyle(selected.category);
    return DashboardAnnouncement(
      title: selected.title,
      message: _summarize(selected.message),
      icon: colorScheme.icon,
      tint: colorScheme.tint,
      backgroundColor: colorScheme.background,
      onTap: () => Navigator.pushNamed(context, '/manager-announcements'),
    );
  }

  String _summarize(String message, {int maxLength = 110}) {
    final normalized = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxLength) return normalized;
    return '${normalized.substring(0, maxLength - 3)}...';
  }

  ({IconData icon, Color tint, Color background}) _categoryStyle(String category) {
    switch (category) {
      case 'urgent':
        return (
          icon: Icons.warning_rounded,
          tint: const Color(0xFFCC3333),
          background: const Color(0xFFFDEDED),
        );
      case 'reminder':
        return (
          icon: Icons.access_time_rounded,
          tint: const Color(0xFFB07D10),
          background: const Color(0xFFFFF8E6),
        );
      default:
        return (
          icon: Icons.info_outline_rounded,
          tint: const Color(0xFF1A73C8),
          background: const Color(0xFFEBF3FD),
        );
    }
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
                announcement: highlightedAnnouncement,
                isLoading: isAnnouncementLoading,
                onOpenAnnouncements: () =>
                    Navigator.pushNamed(context, '/manager-announcements'),
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
