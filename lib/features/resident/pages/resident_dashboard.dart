import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/manager/announcement_models.dart';
import 'package:mycondo/data/models/manager/resident_bill_group.dart';
import 'package:mycondo/data/repositories/resident/resident_service.dart';

class ResidentDashboard extends StatefulWidget {
  const ResidentDashboard({
    super.key,
    this.onOpenMessages,
  });

  final VoidCallback? onOpenMessages;

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
      backgroundColor: const Color(0xFFF8F7F4),
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
                    _ErrorCard(
                      message: 'Unable to load your dashboard.',
                      onRetry: _refresh,
                    ),
                  ],
                );
              }

              final data = snapshot.data!;
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
                  _PaymentBreakdownButton(bills: data.openBills),
                  const SizedBox(height: 18),
                  _AnnouncementPreview(announcement: data.latestAnnouncement),
                  const SizedBox(height: 18),
                  _QuickActions(onOpenMessages: widget.onOpenMessages),
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
  const _ResidentGreeting({
    required this.firstName,
    required this.unitName,
  });

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
            const Icon(Icons.apartment_rounded, size: 16, color: Color(0xFF5E6A72)),
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
        ? 'None'
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
            color: Colors.white.withOpacity(0.16),
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

class _PaymentBreakdownButton extends StatelessWidget {
  const _PaymentBreakdownButton({required this.bills});

  final List<ResidentBillGroup> bills;

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
                  'View Payment Breakdown',
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PaymentBreakdownSheet(bills: bills),
    );
  }
}

class _PaymentBreakdownSheet extends StatelessWidget {
  const _PaymentBreakdownSheet({required this.bills});

  final List<ResidentBillGroup> bills;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final total = bills.fold<int>(0, (sum, bill) => sum + bill.outstandingAmount);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Breakdown',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (bills.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No open bills right now.',
                  style: TextStyle(color: Color(0xFF777777)),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...bills.map(
                      (bill) => _BreakdownBill(
                        bill: bill,
                        currency: currency,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total Amount Due',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  currency.format(total / 100),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: bills.isEmpty
                    ? null
                    : () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/resident-bills');
                      },
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text('Pay Bill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownBill extends StatelessWidget {
  const _BreakdownBill({
    required this.bill,
    required this.currency,
  });

  final ResidentBillGroup bill;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final dueDate = DateFormat('MMM d, yyyy').format(bill.dueDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  bill.billType,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                'Due $dueDate',
                style: const TextStyle(fontSize: 12, color: Color(0xFF777777)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...bill.bills.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Expanded(child: Text(item.name)),
                  Text(currency.format(item.amount / 100)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementPreview extends StatelessWidget {
  const _AnnouncementPreview({required this.announcement});

  final Announcement? announcement;

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
        onTap: () => Navigator.pushNamed(context, '/resident-announcements'),
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
                        ? 'Updates from management will appear here.'
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

  ({IconData icon, Color tint, Color background}) _categoryStyle(String category) {
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
  const _QuickActions({this.onOpenMessages});

  final VoidCallback? onOpenMessages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          title: 'Pay Bill',
          subtitle: 'Review dues and submit payment for approval.',
          icon: Icons.payments_outlined,
          onTap: () => Navigator.pushNamed(context, '/resident-bills'),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          title: 'Message Manager',
          subtitle: 'Ask about dues, repairs, or building updates.',
          icon: Icons.chat_bubble_outline_rounded,
          onTap: onOpenMessages ?? () {},
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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

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
              Icon(icon, color: Colors.black, size: 30),
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
      children: const [
        SizedBox(height: 260, child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(message, style: const TextStyle(color: Color(0xFFB3261E))),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
