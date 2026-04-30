import 'package:flutter/material.dart';
import 'package:mycondo/features/resident/pages/resident_bills_page.dart';
import 'package:mycondo/features/resident/pages/resident_manager_chat_screen.dart';
import 'package:mycondo/features/resident/pages/resident_profile_page.dart';
import 'package:mycondo/features/shared/pages/placeholder_page.dart';
import 'resident_dashboard.dart';
import 'package:mycondo/features/shared/widgets/dashboard_navigation_bar.dart';

class ResidentHomeScreen extends StatefulWidget {
  const ResidentHomeScreen({super.key});

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  int _activePageIndex = 0;

  void changeActivePageIndex(int index) {
    setState(() => _activePageIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ResidentDashboard(onOpenMessages: () => changeActivePageIndex(2)),
      const ResidentBillsPage(showBackButton: false, paidOnly: true),
      const ResidentManagerChatScreen(),
      const PlaceholderPage(title: 'Resident About'),
      const ResidentProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _activePageIndex,
        children: pages,
      ),
      bottomNavigationBar: DashboardNavigationBar(
        currentIndex: _activePageIndex,
        changeActivePageIndex: changeActivePageIndex,
      ),
    );
  }
}
