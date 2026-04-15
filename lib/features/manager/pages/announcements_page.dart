import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mycondo/data/models/manager/announcement_models.dart';
import 'package:mycondo/data/repositories/manager/manager_announcement_service.dart';
import 'package:mycondo/features/manager/widgets/announcement_card.dart';
import 'package:mycondo/features/manager/widgets/announcement_form_sheet.dart';
import 'package:mycondo/features/manager/widgets/dashboard_navigation_bar.dart';

class ManagerAnnouncementsPage extends StatefulWidget {
  const ManagerAnnouncementsPage({super.key});

  @override
  State<ManagerAnnouncementsPage> createState() =>
      _ManagerAnnouncementsPageState();
}

class _ManagerAnnouncementsPageState extends State<ManagerAnnouncementsPage> {
  final ManagerAnnouncementService _service = ManagerAnnouncementService();

  List<Announcement> _announcements = [];
  String _managerName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _service.getAnnouncements(),
      _service.getManagerName(),
    ]);

    if (!mounted) return;
    setState(() {
      _announcements = results[0] as List<Announcement>;
      _managerName = (results[1] as String?) ?? '';
      _loading = false;
    });
  }

  Future<void> _refresh() => _loadData();

  void _openPostForm({Announcement? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnnouncementFormSheet(
        existing: existing,
        managerName: _managerName,
        onSave: (title, message, category) async {
          if (existing != null) {
            await _service.updateAnnouncement(
                existing.id, title, message, category);
          } else {
            await _service.createAnnouncement(
              Announcement(
                id: 0,
                title: title,
                message: message,
                category: category,
                createdAt: DateTime.now(),
                postedBy: _managerName,
              ),
            );
          }
          await _loadData();
        },
      ),
    );
  }

  Future<void> _deleteAnnouncement(Announcement ann) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Announcement',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
            'Are you sure you want to delete this announcement? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFCC3333))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.deleteAnnouncement(ann.id);
      await _loadData();
    }
  }

  /// Group announcements into Today / Yesterday / Earlier
  Map<String, List<Announcement>> _grouped() {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayKey =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    final Map<String, List<Announcement>> groups = {};
    for (final ann in _announcements) {
      final dayKey = DateFormat('yyyy-MM-dd').format(ann.createdAt.toLocal());
      String label;
      if (dayKey == todayKey) {
        label = 'Today';
      } else if (dayKey == yesterdayKey) {
        label = 'Yesterday';
      } else {
        label = DateFormat('MMMM d, yyyy').format(ann.createdAt.toLocal());
      }
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
            // ─── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Row(
                      children: [
                        Icon(Icons.chevron_left_rounded,
                            size: 22, color: Color(0xFF333333)),
                        SizedBox(width: 2),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Announcements',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  _PostNewButton(onTap: () => _openPostForm()),
                ],
              ),
            ),
            // ─── Body ─────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF3A8FE8)))
                  : _announcements.isEmpty
                      ? _EmptyState(onPost: () => _openPostForm())
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          color: const Color(0xFF3A8FE8),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            children: [
                              for (final entry in _grouped().entries) ...[
                                _GroupLabel(label: entry.key),
                                ...entry.value.map(
                                  (ann) => AnnouncementCard(
                                    announcement: ann,
                                    onEdit: () =>
                                        _openPostForm(existing: ann),
                                    onDelete: () =>
                                        _deleteAnnouncement(ann),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DashboardNavigationBar(),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _PostNewButton extends StatelessWidget {
  const _PostNewButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF3A8FE8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Post New',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
          fontWeight: FontWeight.w600,
          color: Color(0xFF666666),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPost});
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x15000000),
                    blurRadius: 16,
                    offset: Offset(0, 4))
              ],
            ),
            child: const Icon(Icons.campaign_outlined,
                size: 36, color: Color(0xFFAAAAAA)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No announcements yet',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap "Post New" to create one.',
            style:
                TextStyle(fontSize: 13, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onPost,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 22, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF3A8FE8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '+ Post New',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
