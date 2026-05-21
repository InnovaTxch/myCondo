import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/manager/announcement_models.dart';
import 'package:mycondo/data/repositories/resident/resident_service.dart';
import 'package:mycondo/services/shared/session_timer_service.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';

class ResidentDashboard extends StatefulWidget {
  const ResidentDashboard({
    super.key,
    this.onOpenMessages,
    this.showPaymentNotificationBadge = false,
    this.showMaintenanceNotificationBadge = false,
    this.onPaymentNotificationsViewed,
    this.onMaintenanceNotificationsViewed,
    this.onAnnouncementNotificationsViewed,
  });

  final VoidCallback? onOpenMessages;
  final bool showPaymentNotificationBadge;
  final bool showMaintenanceNotificationBadge;
  final VoidCallback? onPaymentNotificationsViewed;
  final VoidCallback? onMaintenanceNotificationsViewed;
  final VoidCallback? onAnnouncementNotificationsViewed;

  @override
  State<ResidentDashboard> createState() => _ResidentDashboardState();
}

class _ResidentDashboardState extends State<ResidentDashboard> {
  final ResidentService _service = ResidentService();
  late Future<ResidentDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _service.fetchDashboardData();
    SessionTimerService().startTimer('resident');
  }

  Future<void> _refresh() async {
    final future = _service.fetchDashboardData();
    setState(() {
      _dashboardFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<ResidentDashboardData>(
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
                        message: 'Unable to load your dashboard. Try again.',
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
                  padding: const EdgeInsets.all(24),
                  children: [
                    SizedBox(
                      height: 260,
                      child: AppErrorState(
                        message: 'No dashboard data found. Try again.',
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
                  _ResidentGreeting(
                    firstName: data.firstName,
                    unitName: data.unitName,
                  ),
                  const SizedBox(height: 22),
                  _ResidentMatrix(data: data),
                  const SizedBox(height: 18),
                  const _BillBreakdownButton(),
                  const SizedBox(height: 18),
                  _AnnouncementPreview(
                    announcement: data.latestAnnouncement,
                    onOpened: widget.onAnnouncementNotificationsViewed,
                  ),
                  const SizedBox(height: 18),
                  _QuickActions(
                    onOpenMessages: widget.onOpenMessages,
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

class _ResidentGreeting extends StatelessWidget {
  const _ResidentGreeting({required this.firstName, required this.unitName});

  final String firstName;
  final String unitName;

  @override
  Widget build(BuildContext context) {
    final displayName = firstName.isEmpty ? 'Resident' : firstName;
    final displayUnit = unitName.isEmpty ? 'Unit not assigned' : unitName;

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
        Row(
          children: [
            const Icon(
              Icons.apartment_rounded,
              size: 16,
              color: Color(0xFF5E6A72),
            ),
            const SizedBox(width: 6),
            Text(
              displayUnit,
              style: const TextStyle(
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

class _ResidentMatrix extends StatelessWidget {
  const _ResidentMatrix({required this.data});

  final ResidentDashboardData data;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final nextDue = data.nextDueDate == null
        ? '--'
        : DateFormat('MMM d').format(data.nextDueDate!);

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
            'Amount Due',
            style: TextStyle(
              color: Color(0xDDEAF5FF),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(data.outstandingAmount / 100),
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
                  icon: Icons.receipt_long_outlined,
                  label: 'Bills',
                  value: data.openBillsCount.toString(),
                ),
              ),
              Expanded(
                child: _MetricItem(
                  icon: Icons.event_available_outlined,
                  label: 'Next Due',
                  value: nextDue,
                ),
              ),
              Expanded(
                child: _MetricItem(
                  icon: Icons.warning_amber_rounded,
                  label: 'Overdue',
                  value: data.overdueBillsCount.toString(),
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
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

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

class _BillBreakdownButton extends StatelessWidget {
  const _BillBreakdownButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _openBreakdown(context),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8E4DD)),
          ),
          child: const Row(
            children: [
              Icon(Icons.list_alt_rounded, color: Colors.black, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'View Bill Breakdown',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFFD7D3CC)),
            ],
          ),
        ),
      ),
    );
  }

  void _openBreakdown(BuildContext context) {
    Navigator.pushNamed(context, '/resident-bill-breakdown');
  }
}

class _AnnouncementPreview extends StatelessWidget {
  const _AnnouncementPreview({required this.announcement, this.onOpened});

  final Announcement? announcement;
  final VoidCallback? onOpened;

  @override
  Widget build(BuildContext context) {
    final style = _categoryStyle(announcement?.category ?? 'info');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E3DE)),
      ),
      child: InkWell(
        onTap: () {
          onOpened?.call();
          Navigator.pushNamed(context, '/resident-announcements');
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(style.icon, color: style.tint, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Announcements',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    announcement?.title ?? 'No announcements yet',
                    style: TextStyle(
                      color: style.tint,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    announcement == null
                        ? 'Announcements from management will appear here.'
                        : _summarize(announcement!.message),
                    style: const TextStyle(
                      color: Color(0xFF6A6A6A),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFAAA59D)),
          ],
        ),
      ),
    );
  }

  String _summarize(String message) {
    final normalized = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 96) return normalized;
    return '${normalized.substring(0, 93)}...';
  }

  ({IconData icon, Color tint, Color background}) _categoryStyle(
    String category,
  ) {
    switch (category) {
      case 'urgent':
        return (
          icon: Icons.warning_rounded,
          tint: const Color(0xFFCC3333),
          background: const Color(0xFFFDEDED),
        );
      case 'reminder':
        return (
          icon: Icons.access_time_rounded,
          tint: const Color(0xFFB07D10),
          background: const Color(0xFFFFF8E6),
        );
      default:
        return (
          icon: Icons.info_outline_rounded,
          tint: const Color(0xFF1A73C8),
          background: const Color(0xFFEBF3FD),
        );
    }
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    this.onOpenMessages,
    required this.showPaymentNotificationBadge,
    required this.showMaintenanceNotificationBadge,
    this.onPaymentNotificationsViewed,
    this.onMaintenanceNotificationsViewed,
  });

  final VoidCallback? onOpenMessages;
  final bool showPaymentNotificationBadge;
  final bool showMaintenanceNotificationBadge;
  final VoidCallback? onPaymentNotificationsViewed;
  final VoidCallback? onMaintenanceNotificationsViewed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          title: 'Unit Bill',
          subtitle: 'View shared unit dues, payments, and remaining balance.',
          icon: Icons.apartment_outlined,
          onTap: () => Navigator.pushNamed(context, '/resident-unit-bill'),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          title: 'Pay Bill',
          subtitle: 'Review bills and submit payment for approval.',
          icon: Icons.payments_outlined,
          showBadge: showPaymentNotificationBadge,
          onTap: () {
            onPaymentNotificationsViewed?.call();
            Navigator.pushNamed(context, '/resident-bills');
          },
        ),
        const SizedBox(height: 10),
        _ActionTile(
          title: 'Message Manager',
          subtitle: 'Ask about bills, repairs, or announcements.',
          icon: Icons.chat_bubble_outline_rounded,
          onTap: onOpenMessages ?? () {},
        ),
        const SizedBox(height: 10),
        _ActionTile(
          title: 'Maintenance',
          subtitle: 'Track requests and submit unit repair concerns.',
          icon: Icons.build_circle_outlined,
          showBadge: showMaintenanceNotificationBadge,
          onTap: () {
            onMaintenanceNotificationsViewed?.call();
            Navigator.pushNamed(context, '/resident-maintenance-request');
          },
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
