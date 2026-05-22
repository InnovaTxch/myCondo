import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/manager/announcement_models.dart';
import 'package:mycondo/data/repositories/resident/resident_service.dart';
import 'package:mycondo/services/shared/session_timer_service.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/utils/app_snackbar.dart';

class ResidentDashboard extends StatefulWidget {
  const ResidentDashboard({
    super.key,
    this.showPaymentNotificationBadge = false,
    this.showMaintenanceNotificationBadge = false,
    this.onPaymentNotificationsViewed,
    this.onMaintenanceNotificationsViewed,
    this.onAnnouncementNotificationsViewed,
  });

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
  int? _acknowledgingAnnouncementId;

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

  Future<void> _acknowledgeAnnouncement(Announcement announcement) async {
    if (_acknowledgingAnnouncementId != null) return;
    setState(() {
      _acknowledgingAnnouncementId = announcement.id;
    });
    try {
      await _service.acknowledgeAnnouncement(announcement.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement acknowledged.')),
      );
      await _refresh();
    } catch (error, stackTrace) {
      if (!mounted) return;
      context.showAppError(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Could not acknowledge the announcement.',
        debugLabel: 'ResidentDashboard.acknowledgeAnnouncement',
      );
    } finally {
      if (mounted) {
        setState(() {
          _acknowledgingAnnouncementId = null;
        });
      }
    }
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
                debugPrint(
                  '[ResidentDashboard.load] ${snapshot.error}\n${snapshot.stackTrace ?? ''}',
                );
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  children: [
                    SizedBox(
                      height: 260,
                      child: AppErrorState(
                        message: 'Unable to load your dashboard. Try again.',
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
                  _AnnouncementPreview(
                    announcements: data.announcements,
                    acknowledgedIds: data.acknowledgedAnnouncementIds,
                    acknowledgingAnnouncementId: _acknowledgingAnnouncementId,
                    onAcknowledge: _acknowledgeAnnouncement,
                    onOpened: widget.onAnnouncementNotificationsViewed,
                  ),
                  const SizedBox(height: 18),
                  _QuickActions(
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

class _AnnouncementPreview extends StatelessWidget {
  const _AnnouncementPreview({
    required this.announcements,
    required this.acknowledgedIds,
    required this.acknowledgingAnnouncementId,
    required this.onAcknowledge,
    this.onOpened,
  });

  final List<Announcement> announcements;
  final Set<int> acknowledgedIds;
  final int? acknowledgingAnnouncementId;
  final Future<void> Function(Announcement announcement) onAcknowledge;
  final VoidCallback? onOpened;

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) {
      return const _EmptyAnnouncementCard();
    }

    final announcement = announcements.first;
    final style = _styleFor(announcement.category);
    final needsAcknowledgement =
        announcement.requiresAck && !acknowledgedIds.contains(announcement.id);
    final reason = _priorityReason(
      announcement,
      needsAcknowledgement: needsAcknowledgement,
    );
    final acknowledging = acknowledgingAnnouncementId == announcement.id;
    final message = _summarize(announcement.message);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onOpened?.call();
          Navigator.pushNamed(context, '/resident-announcements');
        },
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
                    if (needsAcknowledgement)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton(
                          onPressed: acknowledging
                              ? null
                              : () => onAcknowledge(announcement),
                          style: FilledButton.styleFrom(
                            backgroundColor: style.tint,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: acknowledging
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Acknowledge',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
                      )
                    else
                      Text(
                        'Tap to open all announcements',
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

  String _priorityReason(
    Announcement ann, {
    required bool needsAcknowledgement,
  }) {
    if (ann.isPinned) return 'PINNED';
    if (needsAcknowledgement) return 'NEEDS ACK';
    if (ann.category == 'urgent') return 'URGENT';
    if (ann.priority == 'high') return 'HIGH PRIORITY';
    if (ann.category == 'reminder') return 'REMINDER';
    return 'LATEST';
  }

  String _postedLabel(DateTime createdAt) {
    return 'Posted ${DateFormat('MMM d, h:mm a').format(createdAt.toLocal())}';
  }

  String _summarize(String message) {
    final normalized = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 120) return normalized;
    return '${normalized.substring(0, 117)}...';
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

class _EmptyAnnouncementCard extends StatelessWidget {
  const _EmptyAnnouncementCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.pushNamed(context, '/resident-announcements'),
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.showPaymentNotificationBadge,
    required this.showMaintenanceNotificationBadge,
    this.onPaymentNotificationsViewed,
    this.onMaintenanceNotificationsViewed,
  });

  final bool showPaymentNotificationBadge;
  final bool showMaintenanceNotificationBadge;
  final VoidCallback? onPaymentNotificationsViewed;
  final VoidCallback? onMaintenanceNotificationsViewed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          title: 'View Bill Breakdown',
          subtitle:
              'See all bill charges, due dates, and payment status details.',
          icon: Icons.list_alt_rounded,
          onTap: () => Navigator.pushNamed(context, '/resident-bill-breakdown'),
        ),
        const SizedBox(height: 10),
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
