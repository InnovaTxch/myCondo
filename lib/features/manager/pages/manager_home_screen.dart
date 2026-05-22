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
  bool _hasHomeNotificationBadge = false;
  bool _hasPaymentNotificationBadge = false;
  bool _hasMaintenanceNotificationBadge = false;

  @override
  void initState() {
    super.initState();
    _activePageIndex = widget.initialPageIndex;
    presenceService.start();
    _loadInitialNotificationSnapshot();
    _actionPopupSubscription = _notificationService
        .managerActionPopupsStream()
        .listen(_showActionPopup);
  }

  Future<void> _loadInitialNotificationSnapshot() async {
    try {
      final snapshot = await _notificationService.getManagerInitialSnapshot();
      if (!mounted) return;
      setState(() {
        _hasPaymentNotificationBadge = snapshot.hasPaymentNotifications;
        _hasMaintenanceNotificationBadge = snapshot.hasMaintenanceNotifications;
        _hasHomeNotificationBadge =
            _hasPaymentNotificationBadge || _hasMaintenanceNotificationBadge;
      });
    } catch (_) {
      // Ignore snapshot failures; realtime stream can still populate badges.
    }
  }

  void changeActivePageIndex(int index) {
    setState(() => _activePageIndex = index);
  }

  void _showActionPopup(String message) {
    if (!mounted) return;
    final text = message.trim();
    if (text.isEmpty) return;
    _markNotificationFlags(text);
    context.showAppMessage(
      text,
      tone: AppSnackTone.info,
      replaceCurrent: false,
    );
  }

  void _markNotificationFlags(String message) {
    final lower = message.toLowerCase();
    var categoryChanged = false;

    if (lower.contains('payment') && !_hasPaymentNotificationBadge) {
      _hasPaymentNotificationBadge = true;
      categoryChanged = true;
    }
    if (lower.contains('maintenance') && !_hasMaintenanceNotificationBadge) {
      _hasMaintenanceNotificationBadge = true;
      categoryChanged = true;
    }

    final nextHome =
        _hasPaymentNotificationBadge || _hasMaintenanceNotificationBadge;
    final homeChanged = _hasHomeNotificationBadge != nextHome;
    if (!categoryChanged && !homeChanged) return;

    setState(() {
      _hasHomeNotificationBadge = nextHome;
    });
  }

  void _syncHomeNotificationBadge() {
    final next =
        _hasPaymentNotificationBadge || _hasMaintenanceNotificationBadge;
    if (_hasHomeNotificationBadge == next) return;
    setState(() {
      _hasHomeNotificationBadge = next;
    });
  }

  void _clearPaymentBadge() {
    if (!_hasPaymentNotificationBadge) return;
    _hasPaymentNotificationBadge = false;
    _syncHomeNotificationBadge();
  }

  void _clearMaintenanceBadge() {
    if (!_hasMaintenanceNotificationBadge) return;
    _hasMaintenanceNotificationBadge = false;
    _syncHomeNotificationBadge();
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
            showPaymentNotificationBadge: _hasPaymentNotificationBadge,
            showMaintenanceNotificationBadge: _hasMaintenanceNotificationBadge,
            onPaymentNotificationsViewed: _clearPaymentBadge,
            onMaintenanceNotificationsViewed: _clearMaintenanceBadge,
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
              hasHomeNotifications: _hasHomeNotificationBadge,
            );
          },
        );
      },
    );
  }
}
