import 'package:flutter/material.dart';

import 'dashboard_quick_action_tile.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    // Quick actions are a single vertical list (not a grid). Using a GridView
    // tends to reserve awkward extra space and feels "stretched" on web.
    return Column(
      children: [
        DashboardQuickActionTile(
          title: 'Manage Residents',
          subtitle: 'View residents by unit and capacity.',
          icon: Icons.person_search_outlined,
          onTap: () => Navigator.pushNamed(context, '/manage-residents'),
        ),
        const SizedBox(height: 10),
        DashboardQuickActionTile(
          title: 'Manage Condo',
          subtitle: 'Add, edit, and delete condo units here.',
          icon: Icons.apartment_outlined,
          onTap: () => Navigator.pushNamed(context, '/manage-condo'),
        ),
        const SizedBox(height: 10),
        DashboardQuickActionTile(
          title: 'Approve Payments',
          subtitle: 'Approve cash and e-wallet payments here.',
          icon: Icons.fact_check_outlined,
          onTap: () => Navigator.pushNamed(context, '/approve-payments'),
        ),
        const SizedBox(height: 10),
        DashboardQuickActionTile(
          title: 'Resident Bills',
          subtitle: 'Create and send bills to residents.',
          icon: Icons.calendar_month_outlined,
          onTap: () => Navigator.pushNamed(context, '/add-bills'),
        ),
        const SizedBox(height: 10),
        DashboardQuickActionTile(
          title: 'Maintenance Requests',
          subtitle: 'Review resident maintenance requests.',
          icon: Icons.receipt_long_outlined,
        ),
      ],
    );
  }
}
