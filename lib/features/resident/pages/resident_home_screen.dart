import 'package:flutter/material.dart';
import 'package:mycondo/features/resident/pages/resident_manager_chat_screen.dart';
import 'package:mycondo/features/resident/pages/resident_profile_page.dart';
import 'resident_dashboard.dart';
import 'package:mycondo/features/shared/pages/placeholder_page.dart';
import 'package:mycondo/features/shared/widgets/dashboard_navigation_bar.dart';

class ResidentHomeScreen extends StatefulWidget {
  const ResidentHomeScreen({super.key});

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  int _activePageIndex = 0;

  final List<Widget> _pages = [
    const ResidentDashboard(),
    const PlaceholderPage(title: 'Resident Payment History'),
    const ResidentManagerChatScreen(),
    const PlaceholderPage(title: 'Resident About'),
    const ResidentProfilePage(),
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
      ),
    );
  }
}
