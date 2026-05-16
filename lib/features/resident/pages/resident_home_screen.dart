import 'package:flutter/material.dart';
import 'package:mycondo/app_routes.dart';
import 'package:mycondo/features/resident/pages/resident_bills_page.dart';
import 'package:mycondo/features/resident/pages/resident_manager_chat_screen.dart';
import 'package:mycondo/features/resident/pages/resident_profile_page.dart';
import 'package:mycondo/features/shared/pages/condo_about_page.dart';
import 'resident_dashboard.dart';
import 'package:mycondo/features/shared/widgets/dashboard_navigation_bar.dart';
import 'package:mycondo/features/shared/widgets/dashboard_tab_scaffold.dart';
import 'package:mycondo/services/shared/chat_services.dart';
import 'package:mycondo/services/shared/presence_service.dart';

class ResidentHomeScreen extends StatefulWidget {
  const ResidentHomeScreen({super.key});

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  int _activePageIndex = 0;
  final _messagingService = MessagingService();

  @override
  void initState() {
    super.initState();
    presenceService.start();
  }

  void changeActivePageIndex(int index) {
    setState(() => _activePageIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardTabScaffold(
      currentIndex: _activePageIndex,
      onIndexChanged: changeActivePageIndex,
      routes: AppRoutes.routes,
      tabs: [
        DashboardTabItem(
          root: ResidentDashboard(onOpenMessages: () => changeActivePageIndex(2)),
        ),
        const DashboardTabItem(
          root: ResidentBillsPage(showBackButton: false, paidOnly: true),
        ),
        const DashboardTabItem(
          root: ResidentManagerChatScreen(),
        ),
        const DashboardTabItem(
          root: CondoAboutPage(canEdit: false),
        ),
        DashboardTabItem(
          root: ResidentProfilePage(
            onContactAdministration: () => changeActivePageIndex(2),
          ),
        ),
      ],
      bottomNavigationBar: (currentIndex, onIndexChanged) {
        return StreamBuilder<bool>(
          stream: _messagingService.hasUnreadMessagesStream(),
          builder: (context, snapshot) {
            return DashboardNavigationBar(
              currentIndex: currentIndex,
              changeActivePageIndex: onIndexChanged,
              hasUnreadMessages: snapshot.data ?? false,
            );
          },
        );
      },
    );
  }
}
