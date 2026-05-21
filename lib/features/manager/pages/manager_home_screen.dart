import 'dart:async';

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
import 'package:mycondo/services/shared/notification_service.dart';
import 'package:mycondo/services/shared/presence_service.dart';
import 'package:mycondo/utils/app_snackbar.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key, this.initialPageIndex = 0});

  final int initialPageIndex;

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  late int _activePageIndex;
  final _messagingService = MessagingService();
  final _notificationService = NotificationService();
  StreamSubscription<String>? _actionPopupSubscription;

  @override
  void initState() {
    super.initState();
    _activePageIndex = widget.initialPageIndex;
    presenceService.start();
    _actionPopupSubscription = _notificationService
        .managerActionPopupsStream()
        .listen(_showActionPopup);
  }

  void changeActivePageIndex(int index) {
    setState(() => _activePageIndex = index);
  }

  void _showActionPopup(String message) {
    if (!mounted) return;
    final text = message.trim();
    if (text.isEmpty) return;
    context.showAppMessage(
      text,
      tone: AppSnackTone.info,
      replaceCurrent: false,
    );
  }

  @override
  void dispose() {
    _actionPopupSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardTabScaffold(
      currentIndex: _activePageIndex,
      onIndexChanged: changeActivePageIndex,
      routes: AppRoutes.routes,
      tabs: [
        DashboardTabItem(
          root: ManagerDashboardPage(
            onOpenPaymentHistory: () => changeActivePageIndex(1),
          ),
        ),
        DashboardTabItem(root: ManagerTransactionHistoryPage()),
        DashboardTabItem(root: ManagerInboxScreen()),
        DashboardTabItem(root: CondoAboutPage(canEdit: true)),
        DashboardTabItem(root: ManagerProfilePage()),
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
