import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/theme/app_theme.dart';

import 'package:mycondo/data/models/manager/announcement_models.dart';
import 'package:mycondo/data/models/manager/dashboard_models.dart';
import 'package:mycondo/data/repositories/manager/manager_announcement_service.dart';
import 'package:mycondo/data/repositories/manager/manager_dashboard_service.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/services/shared/session_timer_service.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({
    super.key,
    required this.onOpenPaymentHistory,
    this.showPaymentNotificationBadge = false,
    this.showMaintenanceNotificationBadge = false,
    this.onPaymentNotificationsViewed,
    this.onMaintenanceNotificationsViewed,
  });

  final VoidCallback onOpenPaymentHistory;
  final bool showPaymentNotificationBadge;
  final bool showMaintenanceNotificationBadge;
  final VoidCallback? onPaymentNotificationsViewed;
  final VoidCallback? onMaintenanceNotificationsViewed;

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> {
  final ManagerDashboardService _dashboardService = ManagerDashboardService();
  final ManagerAnnouncementService _announcementService =
      ManagerAnnouncementService();

  late Future<_ManagerDashboardViewData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
    SessionTimerService().startTimer('manager');
  }

  Future<_ManagerDashboardViewData> _loadDashboard() async {
    final results = await Future.wait([
      _dashboardService.getFirstName(),
      _dashboardService.getDashboardSummary(),
      _announcementService.getVisibleAnnouncementsForManager(),
    ]);

    final managerName = results[0] as String?;
    final summary = results[1] as DashboardSummary;
    final announcements = results[2] as List<Announcement>;

    return _ManagerDashboardViewData(
      managerName: managerName,
      summary: summary,
      announcements: announcements,
    );
  }

  Future<void> _refresh() async {
    final future = _loadDashboard();
    setState(() {
      _dashboardFuture = future;
    });
    await future;
  }

  Future<void> _openAnnouncements() async {
    final changed = await Navigator.pushNamed(
      context,
      '/manager-announcements',
    );
    if (!mounted) return;
    if (changed == true) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<_ManagerDashboardViewData>(
            future: _dashboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _DashboardLoading();
              }

              if (snapshot.hasError) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  children: [
                    SizedBox(
                      height: 260,
                      child: AppErrorState(
                        message: 'Unable to load the manager dashboard.',
                        details: '${snapshot.error}',
                        onRetry: _refresh,
                      ),
                    ),
                  ],
                );
              }

              final data = snapshot.data;
              if (data == null) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  children: [
                    SizedBox(
                      height: 260,
                      child: AppErrorState(
                        message: 'No manager dashboard data found. Try again.',
                        onRetry: _refresh,
                      ),
                    ),
                  ],
                );
              }

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  _ManagerGreeting(managerName: data.managerName),
                  const SizedBox(height: 22),
                  _ManagerSummaryCard(summary: data.summary),
                  const SizedBox(height: 18),
                  _ManagerAnnouncementPreview(
                    announcements: data.announcements,
                    onTap: _openAnnouncements,
                  ),
                  const SizedBox(height: 18),
                  _ManagerQuickActions(
                    onOpenPaymentHistory: widget.onOpenPaymentHistory,
                    showPaymentNotificationBadge:
                        widget.showPaymentNotificationBadge,
                    showMaintenanceNotificationBadge:
                        widget.showMaintenanceNotificationBadge,
                    onPaymentNotificationsViewed:
                        widget.onPaymentNotificationsViewed,
                    onMaintenanceNotificationsViewed:
                        widget.onMaintenanceNotificationsViewed,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ManagerDashboardViewData {
  const _ManagerDashboardViewData({
    required this.managerName,
    required this.summary,
    required this.announcements,
  });

  final String? managerName;
  final DashboardSummary summary;
  final List<Announcement> announcements;
}

class _ManagerGreeting extends StatelessWidget {
  const _ManagerGreeting({required this.managerName});

  final String? managerName;

  @override
  Widget build(BuildContext context) {
    final displayName = (managerName ?? '').trim().isEmpty
        ? 'Manager'
        : managerName!.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Colors.black,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          displayName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.apartment_rounded, size: 16, color: Color(0xFF5E6A72)),
            SizedBox(width: 6),
            Text(
              'Condo operations overview',
              style: TextStyle(
                color: Color(0xFF5E6A72),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ManagerSummaryCard extends StatelessWidget {
  const _ManagerSummaryCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final occupancyValue = summary.occupancyPercent == null
        ? '--'
        : '${(summary.occupancyPercent!.clamp(0, 1) * 100).round()}%';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B72D9),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x240B72D9),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Snapshot',
            style: TextStyle(
              color: Color(0xDDEAF5FF),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.activeUnits ?? 0} active units',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  icon: Icons.meeting_room_outlined,
                  label: 'Units',
                  value: '${summary.totalUnits ?? 0}',
                ),
              ),
              Expanded(
                child: _MetricItem(
                  icon: Icons.people_alt_outlined,
                  label: 'Residents',
                  value: '${summary.totalResidents ?? 0}',
                ),
              ),
              Expanded(
                child: _MetricItem(
                  icon: Icons.fact_check_outlined,
                  label: 'Review',
                  value: '${summary.paymentsToReview ?? 0}',
                ),
              ),
              Expanded(
                child: _MetricItem(
                  icon: Icons.pie_chart_outline_rounded,
                  label: 'Occupied',
                  value: occupancyValue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xDDEAF5FF),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ManagerAnnouncementPreview extends StatelessWidget {
  const _ManagerAnnouncementPreview({
    required this.announcements,
    required this.onTap,
  });

  final List<Announcement> announcements;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) {
      return const _EmptyManagerAnnouncementCard();
    }

    final announcement = announcements.first;
    final style = _styleFor(announcement.category);
    final reason = _priorityReason(announcement);
    final message = _summarize(announcement.message);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: style.border, width: 2.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: style.tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(style.icon, color: style.tint, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Announcements',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1D2329),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          label: reason,
                          textColor: style.tint,
                          background: style.tint.withValues(alpha: 0.13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      announcement.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: style.tint,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _postedLabel(announcement.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF5A6570),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF404A54),
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Tap to manage announcements',
                      style: TextStyle(
                        color: style.tint,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: style.tint.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _priorityReason(Announcement ann) {
    if (ann.isPinned) return 'PINNED';
    if (ann.requiresAck) return 'REQUIRES ACK';
    if (ann.category == 'urgent') return 'URGENT';
    if (ann.priority == 'high') return 'HIGH PRIORITY';
    if (ann.category == 'reminder') return 'REMINDER';
    return 'LATEST';
  }

  String _summarize(String message, {int maxLength = 110}) {
    final normalized = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxLength) return normalized;
    return '${normalized.substring(0, maxLength - 3)}...';
  }

  String _postedLabel(DateTime createdAt) {
    return 'Posted ${DateFormat('MMM d, h:mm a').format(createdAt.toLocal())}';
  }

  ({IconData icon, Color tint, Color border}) _styleFor(String category) {
    switch (category) {
      case 'urgent':
        return (
          icon: Icons.warning_rounded,
          tint: const Color(0xFFB72D2D),
          border: const Color(0xFFE48A8A),
        );
      case 'reminder':
        return (
          icon: Icons.access_time_rounded,
          tint: const Color(0xFFD4A017),
          border: const Color(0xFFE8C56A),
        );
      default:
        return (
          icon: Icons.info_outline_rounded,
          tint: const Color(0xFF1A73C8),
          border: const Color(0xFF8EBCEA),
        );
    }
  }
}

class _EmptyManagerAnnouncementCard extends StatelessWidget {
  const _EmptyManagerAnnouncementCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.pushNamed(context, '/manager-announcements'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE6E3DE), width: 1.2),
          ),
          child: const Row(
            children: [
              Icon(Icons.campaign_outlined, color: Color(0xFF1A73C8), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No announcements yet. Tap to open announcements.',
                  style: TextStyle(
                    color: Color(0xFF404A54),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: Color(0xFF6E7781)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.textColor,
    required this.background,
  });

  final String label;
  final Color textColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _ManagerQuickActions extends StatelessWidget {
  const _ManagerQuickActions({
    required this.onOpenPaymentHistory,
    required this.showPaymentNotificationBadge,
    required this.showMaintenanceNotificationBadge,
    this.onPaymentNotificationsViewed,
    this.onMaintenanceNotificationsViewed,
  });

  final VoidCallback onOpenPaymentHistory;
  final bool showPaymentNotificationBadge;
  final bool showMaintenanceNotificationBadge;
  final VoidCallback? onPaymentNotificationsViewed;
  final VoidCallback? onMaintenanceNotificationsViewed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          title: 'Manage Residents',
          subtitle: 'View assignments, occupancy, and resident details.',
          icon: Icons.people_outline_rounded,
          onTap: () => Navigator.pushNamed(context, '/manage-residents'),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          title: 'Approve Payments',
          subtitle: 'Review cash and e-wallet submissions from residents.',
          icon: Icons.fact_check_outlined,
          showBadge: showPaymentNotificationBadge,
          onTap: () {
            onPaymentNotificationsViewed?.call();
            Navigator.pushNamed(context, '/approve-payments');
          },
        ),
        const SizedBox(height: 10),
        _ActionTile(
          title: 'Manage Units',
          subtitle:
              'Edit unit profile, monthly charges, and unit payment status.',
          icon: Icons.apartment_outlined,
          onTap: () => Navigator.pushNamed(context, '/manage-condo'),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          title: 'Create Bills',
          subtitle: 'Send dues and charges to selected residents.',
          icon: Icons.receipt_long_outlined,
          onTap: () => Navigator.pushNamed(context, '/add-bills'),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          title: 'Maintenance Requests',
          subtitle: 'Review and update resident repair requests.',
          icon: Icons.build_circle_outlined,
          showBadge: showMaintenanceNotificationBadge,
          onTap: () {
            onMaintenanceNotificationsViewed?.call();
            Navigator.pushNamed(context, '/manager-maintenance-requests');
          },
        ),
        const SizedBox(height: 10),
        _ActionTile(
          title: 'Transaction History',
          subtitle: 'Review approved and rejected payment decisions.',
          icon: Icons.history_rounded,
          onTap: onOpenPaymentHistory,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.showBadge = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8E4DD)),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: Colors.black, size: 30),
                  if (showBadge)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A8A8A),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFD7D3CC)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: const [SizedBox(height: 260, child: AppLoadingState())],
    );
  }
}
