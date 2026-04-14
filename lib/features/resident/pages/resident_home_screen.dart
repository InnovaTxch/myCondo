import 'package:flutter/material.dart';

import 'resident_dashboard.dart';
import 'package:mycondo/features/resident/widgets/dashboard_navigation_bar.dart';

class ResidentHomeScreen extends StatefulWidget {
  const ResidentHomeScreen({super.key});

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  int _activePageIndex = 0;

  final List<Widget> _pages = [
    ResidentDashboard(),
    // Resident Payment History Page
    // Resident Inbox Page
    // Resident About
    // Resident Profile
  ];

  void changeActivePageIndex(int index) {
    setState(() => _activePageIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _activePageIndex,
        children: _pages,
      ),
      bottomNavigationBar: DashboardNavigationBar(
        currentIndex: _activePageIndex,
        changeActivePageIndex: changeActivePageIndex,
      )
    );
  }
}