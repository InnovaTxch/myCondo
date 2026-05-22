import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:intl/intl.dart';

import 'package:mycondo/data/models/manager/announcement_models.dart';
import 'package:mycondo/data/repositories/manager/manager_announcement_service.dart';
import 'package:mycondo/features/manager/widgets/announcement_card.dart';
import 'package:mycondo/features/manager/widgets/announcement_form_sheet.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/utils/app_snackbar.dart';

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
  bool _didMutate = false;

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
        onSave: (title, message, category, expiresAt) async {
          if (existing != null) {
            await _service.updateAnnouncement(
              existing.id,
              title,
              message,
              category,
              endsAt: expiresAt,
            );
          } else {
            await _service.createAnnouncement(
              Announcement(
                id: 0,
                title: title,
                message: message,
                category: category,
                createdAt: DateTime.now(),
                endsAt: expiresAt,
                postedBy: _managerName,
              ),
            );
          }
          _didMutate = true;
          await _loadData();
        },
      ),
    );
  }

  Future<bool> _confirmDeleteAnnouncement() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delete Announcement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to delete this announcement? This cannot be undone.',
                  style: TextStyle(color: Color(0xFF666666), height: 1.35),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF444444),
                          side: const BorderSide(color: Color(0xFFE3E3E3)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFCC3333),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  Future<void> _deleteAnnouncement(Announcement ann) async {
    final confirmed = await _confirmDeleteAnnouncement();
    if (confirmed) {
      try {
        await _service.deleteAnnouncement(ann.id);
        _didMutate = true;
        await _loadData();
      } catch (e, st) {
        if (!mounted) return;
        context.showAppError(
          e,
          stackTrace: st,
          fallbackMessage: 'Could not delete the announcement.',
          debugLabel: 'ManagerAnnouncementsPage.deleteAnnouncement',
        );
      }
    }
  }

  /// Group announcements into Today / Yesterday / Earlier
  Map<String, List<Announcement>> _grouped() {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayKey = DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(const Duration(days: 1)));

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_didMutate);
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBlueBackground,
        floatingActionButton: SafeArea(
          minimum: const EdgeInsets.only(right: 4, bottom: 4),
          child: _PostNewButton(onTap: () => _openPostForm()),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
          child: Column(
            children: [
              // ─── Header ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(_didMutate),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.chevron_left_rounded,
                            size: 22,
                            color: Color(0xFF333333),
                          ),
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
                        color: AppColors.darkText,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // ─── Body ─────────────────────────────────────────────────
              Expanded(
                child: _loading
                    ? const AppLoadingState(
                        strokeWidth: 2,
                        color: Color(0xFF3A8FE8),
                      )
                    : _announcements.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _refresh,
                        color: const Color(0xFF3A8FE8),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.6,
                              child: AppEmptyState(
                                icon: Icons.campaign_outlined,
                                title: 'No announcements yet',
                                message: 'Tap "Post New" to create one.',
                                actionLabel: '+ Post New',
                                onAction: () => _openPostForm(),
                                card: false,
                              ),
                            ),
                          ],
                        ),
                      )
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
                                  onEdit: () => _openPostForm(existing: ann),
                                  onDelete: () => _deleteAnnouncement(ann),
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
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _PostNewButton extends StatelessWidget {
  const _PostNewButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3A8FE8),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        mouseCursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
