import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/manager/announcement_models.dart';
import 'package:mycondo/data/repositories/resident/resident_service.dart';

class ResidentAnnouncementsPage extends StatefulWidget {
  const ResidentAnnouncementsPage({
    super.key,
    this.showBackButton = true,
  });

  final bool showBackButton;

  @override
  State<ResidentAnnouncementsPage> createState() =>
      _ResidentAnnouncementsPageState();
}

class _ResidentAnnouncementsPageState extends State<ResidentAnnouncementsPage> {
  final ResidentService _service = ResidentService();
  late Future<List<Announcement>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _announcementsFuture = _service.fetchAnnouncementsForResident();
  }

  Future<void> _refresh() async {
    final future = _service.fetchAnnouncementsForResident();
    setState(() {
      _announcementsFuture = future;
    });
    await future;
  }

  Map<String, List<Announcement>> _grouped(List<Announcement> announcements) {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayKey =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    final groups = <String, List<Announcement>>{};
    for (final ann in announcements) {
      final dayKey = DateFormat('yyyy-MM-dd').format(ann.createdAt.toLocal());
      final label = dayKey == todayKey
          ? 'Today'
          : dayKey == yesterdayKey
              ? 'Yesterday'
              : DateFormat('MMMM d, yyyy').format(ann.createdAt.toLocal());
      groups.putIfAbsent(label, () => []).add(ann);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCECF5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 20, 8),
              child: Row(
                children: [
                  if (widget.showBackButton)
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.chevron_left_rounded),
                    )
                  else
                    const SizedBox(width: 12),
                  const Text(
                    'Announcements',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Announcement>>(
                future: _announcementsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _ErrorState(onRetry: _refresh);
                  }

                  final announcements = snapshot.data ?? const <Announcement>[];
                  if (announcements.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
                        children: const [_EmptyState()],
                      ),
                    );
                  }

                  final grouped = _grouped(announcements);
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        for (final entry in grouped.entries) ...[
                          _GroupLabel(label: entry.key),
                          ...entry.value.map(
                            (announcement) => _ReadOnlyAnnouncementCard(
                              announcement: announcement,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyAnnouncementCard extends StatelessWidget {
  const _ReadOnlyAnnouncementCard({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(announcement.category);
    final postedDate = DateFormat("MMM d, yyyy 'at' h:mm a")
        .format(announcement.createdAt.toLocal());

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: style.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(style.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: style.tint,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Posted on $postedDate',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  announcement.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF444444),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _CategoryStyle _styleFor(String category) {
    switch (category) {
      case 'urgent':
        return const _CategoryStyle(
          icon: Icons.warning_rounded,
          tint: Color(0xFFCC3333),
          iconBg: Color(0xFFE05555),
        );
      case 'reminder':
        return const _CategoryStyle(
          icon: Icons.access_time_rounded,
          tint: Color(0xFFB07D10),
          iconBg: Color(0xFFE8A020),
        );
      default:
        return const _CategoryStyle(
          icon: Icons.info_outline_rounded,
          tint: Color(0xFF1A73C8),
          iconBg: Color(0xFF3A8FE8),
        );
    }
  }
}

class _CategoryStyle {
  const _CategoryStyle({
    required this.icon,
    required this.tint,
    required this.iconBg,
  });

  final IconData icon;
  final Color tint;
  final Color iconBg;
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF666666),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.campaign_outlined, size: 40, color: Color(0xFF999999)),
          SizedBox(height: 12),
          Text(
            'No announcements yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Management updates will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF777777)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton(
        onPressed: onRetry,
        child: const Text('Unable to load announcements. Try again.'),
      ),
    );
  }
}
