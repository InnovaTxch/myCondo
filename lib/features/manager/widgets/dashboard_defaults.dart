import 'package:flutter/material.dart';

import 'package:mycondo/data/models/manager/dashboard_models.dart';

const List<DashboardQuickAction> defaultDashboardQuickActions = [
  DashboardQuickAction(
    title: 'Manage Tenants',
    subtitle: 'Add, edit, and delete tenants here.',
    icon: Icons.person_search_outlined,
  ),
  DashboardQuickAction(
    title: 'Approve Payments',
    subtitle: 'Approve cash and e-wallet payments here.',
    icon: Icons.fact_check_outlined,
  ),
  DashboardQuickAction(
    title: 'Tenant Bills',
    subtitle: 'Add tenant rent dues here.',
    icon: Icons.calendar_month_outlined,
    iconBadgeColor: Color(0xFF80BDF2),
  ),
  DashboardQuickAction(
    title: 'Maintenance Requests',
    subtitle: 'Check all transactions within 24 hours here.',
    icon: Icons.receipt_long_outlined,
  ),
];

const List<DashboardNavigationItem> defaultDashboardNavigationItems = [
  DashboardNavigationItem(icon: Icons.home_outlined),
  DashboardNavigationItem(icon: Icons.access_time_outlined),
  DashboardNavigationItem(icon: Icons.chat_bubble_outline_rounded),
  DashboardNavigationItem(icon: Icons.info_outline_rounded),
  DashboardNavigationItem(icon: Icons.person_outline_rounded),
];
