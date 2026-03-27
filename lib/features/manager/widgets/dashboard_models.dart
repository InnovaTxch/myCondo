import 'package:flutter/material.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.totalTenants,
    required this.pendingReports,
    required this.paymentsToReview,
    required this.completionPercent,
    this.progressLabel = 'rate paid',
  });

  final int? totalTenants;
  final int? pendingReports;
  final int? paymentsToReview;
  final double? completionPercent;
  final String progressLabel;
}

class DashboardAnnouncement {
  const DashboardAnnouncement({
    required this.title,
    required this.message,
    this.icon = Icons.warning_rounded,
    this.tint = const Color(0xFFE5534B),
    this.backgroundColor = const Color(0xFFFBEAEA),
    this.onEdit,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color tint;
  final Color backgroundColor;
  final VoidCallback? onEdit;
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

class DashboardNavigationItem {
  const DashboardNavigationItem({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;
}
