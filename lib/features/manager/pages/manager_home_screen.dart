import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'profile_page.dart';

import 'package:mycondo/features/manager/pages/manager_inbox_screen.dart';
import 'package:mycondo/features/manager/pages/manager_transaction_history_page.dart';
import 'package:mycondo/features/shared/pages/condo_about_page.dart';
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
    const ManagerTransactionHistoryPage(),
    const ManagerInboxScreen(),
    const CondoAboutPage(canEdit: true),
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
