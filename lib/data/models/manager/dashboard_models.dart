import 'package:flutter/material.dart';

class DashboardSummary {
  int? totalTenants;
  int? pendingReports;
  int? paymentsToReview;
  double? completionPercent;
  String? progressLabel;
}

class DashboardAnnouncement {
  const DashboardAnnouncement({
    required this.title,
    required this.message,
    this.icon = Icons.warning_rounded,
    this.tint = const Color(0xFFE5534B),
    this.backgroundColor = const Color(0xFFFBEAEA),
    this.onTap,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color tint;
  final Color backgroundColor;
  final VoidCallback? onTap;
}

class DashboardQuickAction {
  const DashboardQuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconBadgeColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconBadgeColor;
  final VoidCallback? onTap;
}
