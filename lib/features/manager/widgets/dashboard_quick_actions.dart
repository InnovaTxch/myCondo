import 'package:flutter/material.dart';

import 'dashboard_quick_action_tile.dart';

class DashboardQuickActions extends StatelessWidget{
  const DashboardQuickActions({super.key});


  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), 
      crossAxisCount: 1,
      mainAxisSpacing: 10,
      childAspectRatio: 5,
      children: [
        DashboardQuickActionTile(
          title: 'Manage Residents',
          subtitle: 'View residents by unit and capacity.',
          icon: Icons.person_search_outlined,
          onTap: () => Navigator.pushNamed(context, '/manage-residents'),
        ),
        DashboardQuickActionTile(
          title: 'Manage Condo',
          subtitle: 'Add, edit, and delete condo units here.',
          icon: Icons.apartment_outlined,
          onTap: () => Navigator.pushNamed(context, '/manage-condo'),
        ),
        DashboardQuickActionTile(
          title: 'Approve Payments',
          subtitle: 'Approve cash and e-wallet payments here.',
          icon: Icons.fact_check_outlined,
          onTap: () => Navigator.pushNamed(context, '/approve-payments'),
        ),
        DashboardQuickActionTile(
          title: 'Resident Bills',
          subtitle: 'Create and send bills to residents.',
          icon: Icons.calendar_month_outlined,
          onTap: () => Navigator.pushNamed(context, '/add-bills'),
        ),
        DashboardQuickActionTile(
          title: 'Maintenance Requests',
          subtitle: 'Review resident maintenance requests.',
          icon: Icons.receipt_long_outlined,
        ),
      ],
    );
  }
}
