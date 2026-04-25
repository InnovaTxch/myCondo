import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'profile_page.dart';

import 'package:mycondo/features/shared/pages/inbox_screen.dart';
import 'package:mycondo/features/shared/pages/placeholder_page.dart';
import 'package:mycondo/features/shared/widgets/dashboard_navigation_bar.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({
    super.key,
    this.initialPageIndex = 0,
  });

  final int initialPageIndex;

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  late int _activePageIndex;

  final List<Widget> _pages = [
    const ManagerDashboardPage(),
    const PlaceholderPage(title: 'Manager Payment History'),
    const InboxScreen(),
    const PlaceholderPage(title: 'Manager About'),
    const ManagerProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _activePageIndex = widget.initialPageIndex;
  }

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
      ),
    );
  }
}
