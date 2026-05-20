import 'package:flutter/material.dart';

import 'package:mycondo/app_routes.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';

import 'package:mycondo/features/manager/pages/manager_inbox_screen.dart';
import 'package:mycondo/features/manager/pages/manager_transaction_history_page.dart';
import 'package:mycondo/features/shared/pages/condo_about_page.dart';
import 'package:mycondo/features/shared/widgets/dashboard_navigation_bar.dart';
import 'package:mycondo/features/shared/widgets/dashboard_tab_scaffold.dart';
import 'package:mycondo/services/shared/chat_services.dart';
import 'package:mycondo/services/shared/presence_service.dart';

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
  final _messagingService = MessagingService();

  @override
  void initState() {
    super.initState();
    _activePageIndex = widget.initialPageIndex;
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
      tabs: const [
        DashboardTabItem(root: ManagerDashboardPage()),
        DashboardTabItem(root: ManagerTransactionHistoryPage()),
        DashboardTabItem(root: ManagerInboxScreen()),
        DashboardTabItem(root: CondoAboutPage(canEdit: true)),
        DashboardTabItem(root: ManagerProfilePage()),
      ],
      bottomNavigationBar: (currentIndex, onIndexChanged) {
        // Stream 1: unread chat messages
        return StreamBuilder<bool>(
          stream: _messagingService.hasUnreadMessagesStream(),
          builder: (context, msgSnapshot) {
            // Stream 2: pending payments awaiting manager approval (NEW)
            return StreamBuilder<bool>(
              stream: _messagingService.hasPendingPaymentsStream(),
              builder: (context, paySnapshot) {
                return DashboardNavigationBar(
                  currentIndex: currentIndex,
                  changeActivePageIndex: onIndexChanged,
                  hasUnreadMessages: msgSnapshot.data ?? false,
                  hasPaymentNotification: paySnapshot.data ?? false, // NEW
                );
              },
            );
          },
        );
      },
    );
  }
}