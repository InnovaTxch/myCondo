import 'dart:async';

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
import 'package:mycondo/services/shared/notification_service.dart';
import 'package:mycondo/services/shared/presence_service.dart';
import 'package:mycondo/services/push/push_notification_service.dart';
import 'package:mycondo/utils/app_snackbar.dart';

class ResidentHomeScreen extends StatefulWidget {
  const ResidentHomeScreen({super.key});

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  int _activePageIndex = 0;
  final _messagingService = MessagingService();
  final _notificationService = NotificationService();
  StreamSubscription<String>? _actionPopupSubscription;
  bool _hasHomeNotificationBadge = false;
  bool _hasPaymentNotificationBadge = false;
  bool _hasMaintenanceNotificationBadge = false;
  bool _hasAnnouncementNotificationBadge = false;

  @override
  void initState() {
    super.initState();
    unawaited(PushNotificationService.instance.registerCurrentProfileDevice());
    presenceService.start();
    _loadInitialNotificationSnapshot();
    _actionPopupSubscription = _notificationService
        .residentActionPopupsStream()
        .listen(_showActionPopup);
  }

  Future<void> _loadInitialNotificationSnapshot() async {
    try {
      final snapshot = await _notificationService.getResidentInitialSnapshot();
      if (!mounted) return;
      setState(() {
        _hasPaymentNotificationBadge = snapshot.hasPaymentNotifications;
        _hasMaintenanceNotificationBadge = snapshot.hasMaintenanceNotifications;
        _hasAnnouncementNotificationBadge =
            snapshot.hasAnnouncementNotifications;
        _hasHomeNotificationBadge =
            _hasPaymentNotificationBadge ||
            _hasMaintenanceNotificationBadge ||
            _hasAnnouncementNotificationBadge;
      });
    } catch (_) {
      // Ignore snapshot failures; realtime stream can still populate badges.
    }
  }

  void changeActivePageIndex(int index) {
    if (index == 1) {
      _clearPaymentBadge();
    }
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
    if (lower.contains('announcement') && !_hasAnnouncementNotificationBadge) {
      _hasAnnouncementNotificationBadge = true;
      categoryChanged = true;
    }

    final nextHome =
        _hasPaymentNotificationBadge ||
        _hasMaintenanceNotificationBadge ||
        _hasAnnouncementNotificationBadge;
    final homeChanged = _hasHomeNotificationBadge != nextHome;
    if (!categoryChanged && !homeChanged) return;

    setState(() {
      _hasHomeNotificationBadge = nextHome;
    });
  }

  void _syncHomeNotificationBadge() {
    final next =
        _hasPaymentNotificationBadge ||
        _hasMaintenanceNotificationBadge ||
        _hasAnnouncementNotificationBadge;
    if (_hasHomeNotificationBadge == next) return;
    setState(() {
      _hasHomeNotificationBadge = next;
    });
  }

  void _clearPaymentBadge() {
    if (!_hasPaymentNotificationBadge) return;
    _messagingService.clearPaymentStatusNotification();
    _hasPaymentNotificationBadge = false;
    _syncHomeNotificationBadge();
  }

  void _clearMaintenanceBadge() {
    if (!_hasMaintenanceNotificationBadge) return;
    _hasMaintenanceNotificationBadge = false;
    _syncHomeNotificationBadge();
  }

  void _clearAnnouncementBadge() {
    if (!_hasAnnouncementNotificationBadge) return;
    _hasAnnouncementNotificationBadge = false;
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
          root: ResidentDashboard(
            showPaymentNotificationBadge: _hasPaymentNotificationBadge,
            showMaintenanceNotificationBadge: _hasMaintenanceNotificationBadge,
            onPaymentNotificationsViewed: _clearPaymentBadge,
            onMaintenanceNotificationsViewed: _clearMaintenanceBadge,
            onAnnouncementNotificationsViewed: _clearAnnouncementBadge,
          ),
        ),
        const DashboardTabItem(
          root: ResidentBillsPage(showBackButton: false, paidOnly: true),
        ),
        const DashboardTabItem(root: ResidentManagerChatScreen()),
        const DashboardTabItem(root: CondoAboutPage(canEdit: false)),
        DashboardTabItem(
          root: ResidentProfilePage(
            onContactAdministration: () => changeActivePageIndex(2),
            onOpenMaintenanceRequests: () {
              _clearMaintenanceBadge();
              Navigator.pushNamed(context, '/resident-maintenance-request');
            },
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
              hasHomeNotifications: _hasHomeNotificationBadge,
            );
          },
        );
      },
    );
  }
}
