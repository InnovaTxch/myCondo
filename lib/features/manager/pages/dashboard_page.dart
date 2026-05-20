import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';

import 'package:mycondo/data/models/manager/announcement_models.dart';
import 'package:mycondo/data/repositories/manager/manager_dashboard_service.dart';
import 'package:mycondo/data/repositories/manager/manager_announcement_service.dart';
import 'package:mycondo/data/models/manager/dashboard_models.dart';

import '../widgets/dashboard_announcement_section.dart';
import '../widgets/dashboard_greeting.dart';
import '../widgets/dashboard_summary_card.dart';
import '../widgets/dashboard_quick_actions.dart';

import 'package:mycondo/services/shared/session_timer_service.dart';

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

  Future<void> _openAnnouncements() async {
    final changed = await Navigator.pushNamed(context, '/manager-announcements');
    if (!mounted) return;
    if (changed == true) await _initializePage();
  }

  Future<void> _initializePage() async {
    setState(() => isAnnouncementLoading = true);
    try {
      final results = await Future.wait([
        dashboardService.getFirstName(),
        dashboardService.getDashboardSummary(),
        announcementService.getAnnouncements(),
      ]);
      final name = results[0] as String?;
      final dashboardSummary = results[1] as DashboardSummary;
      final announcements = results[2] as List<Announcement>;
      if (!mounted) return;
      setState(() {
        managerName = name;
        summary = dashboardSummary;
        highlightedAnnouncement = _toHighlightedAnnouncement(announcements);
        isAnnouncementLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isAnnouncementLoading = false;
        highlightedAnnouncement = DashboardAnnouncement(
          title: 'Dashboard unavailable',
          message: e.toString(),
          icon: Icons.error_outline_rounded,
          tint: const Color(0xFFB3261E),
          backgroundColor: const Color(0xFFFFEDEA),
          onTap: () {},
        );
      });
    }
  }

  DashboardAnnouncement? _toHighlightedAnnouncement(List<Announcement> announcements) {
    if (announcements.isEmpty) return null;
    Announcement selected = announcements.first;
    for (final ann in announcements) {
      if (ann.category == 'urgent') { selected = ann; break; }
      if (ann.category == 'reminder' && selected.category != 'urgent') selected = ann;
    }
    final colorScheme = _categoryStyle(selected.category);
    return DashboardAnnouncement(
      title: selected.title,
      message: _summarize(selected.message),
      icon: colorScheme.icon,
      tint: colorScheme.tint,
      backgroundColor: colorScheme.background,
      onTap: _openAnnouncements,
    );
  }

  String _summarize(String message, {int maxLength = 110}) {
    final normalized = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxLength) return normalized;
    return '${normalized.substring(0, maxLength - 3)}...';
  }

  ({IconData icon, Color tint, Color background}) _categoryStyle(String category) {
    switch (category) {
      case 'urgent': return (icon: Icons.warning_rounded, tint: const Color(0xFFCC3333), background: const Color(0xFFFDEDED));
      case 'reminder': return (icon: Icons.access_time_rounded, tint: const Color(0xFFB07D10), background: const Color(0xFFFFF8E6));
      default: return (icon: Icons.info_outline_rounded, tint: const Color(0xFF1A73C8), background: const Color(0xFFEBF3FD));
    }
  }

  @override
  void initState() {
    super.initState();
    _initializePage();
    SessionTimerService().startTimer('manager');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: _initializePage,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardGreeting(managerName: managerName ?? ""),
                const SizedBox(height: 16),
                DashboardSummaryCard(summary: summary),
                const SizedBox(height: 16),
                DashboardAnnouncementSection(
                  announcement: highlightedAnnouncement,
                  isLoading: isAnnouncementLoading,
                  onOpenAnnouncements: _openAnnouncements,
                ),
                const SizedBox(height: 16),
                // Section label
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontFamily: "Urbanist",
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryText,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const DashboardQuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}