import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mycondo/data/models/manager/announcement_models.dart';
import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:mycondo/services/push/push_event_dispatcher_service.dart';

class ManagerAnnouncementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileIdentityService _identity = ProfileIdentityService();
  final PushEventDispatcherService _pushDispatcher =
      PushEventDispatcherService();

  Future<List<Announcement>> getAnnouncements() async {
    final manager = await _requireManagerContext();

    final data = await _supabase
        .from('announcements')
        .select()
        .eq('condo_id', manager.condoId)
        .neq('status', 'archived')
        .order('is_pinned', ascending: false)
        .order('starts_at', ascending: false)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => Announcement.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Announcement>> getVisibleAnnouncementsForManager() async {
    final manager = await _requireManagerContext();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final data = await _supabase
        .from('announcements')
        .select()
        .eq('condo_id', manager.condoId)
        .neq('status', 'archived')
        .lte('starts_at', nowIso)
        .or('ends_at.is.null,ends_at.gt.$nowIso')
        .order('is_pinned', ascending: false)
        .order('starts_at', ascending: false)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => Announcement.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Announcement?> getHomeAnnouncementForManager() async {
    final manager = await _requireManagerContext();

    try {
      final data = await _supabase.rpc(
        'get_home_announcement',
        params: {
          'p_condo_id': manager.condoId,
          'p_profile_id': manager.managerId,
        },
      );

      final rows = data as List<dynamic>;
      if (rows.isEmpty) return null;

      return Announcement.fromJson(rows.first as Map<String, dynamic>);
    } on PostgrestException catch (error) {
      if (!_isMissingFunction(error)) rethrow;
      final announcements = await getAnnouncements();
      return _pickHomeAnnouncementFallback(announcements);
    }
  }

  Announcement? _pickHomeAnnouncementFallback(
    List<Announcement> announcements,
  ) {
    if (announcements.isEmpty) return null;
    final visible = announcements.where(_isVisibleNow).toList();
    if (visible.isEmpty) return null;

    visible.sort((a, b) {
      final pin = _boolRank(b.isPinned) - _boolRank(a.isPinned);
      if (pin != 0) return pin;

      final ack = _boolRank(b.requiresAck) - _boolRank(a.requiresAck);
      if (ack != 0) return ack;

      final category = _categoryRank(b.category) - _categoryRank(a.category);
      if (category != 0) return category;

      final priority = _priorityRank(b.priority) - _priorityRank(a.priority);
      if (priority != 0) return priority;

      final aEnds = a.endsAt;
      final bEnds = b.endsAt;
      if (aEnds != null && bEnds != null) {
        final byEndsSooner = aEnds.compareTo(bEnds);
        if (byEndsSooner != 0) return byEndsSooner;
      } else if (aEnds != null && bEnds == null) {
        return -1;
      } else if (aEnds == null && bEnds != null) {
        return 1;
      }

      return b.createdAt.compareTo(a.createdAt);
    });

    return visible.first;
  }

  bool _isVisibleNow(Announcement announcement) {
    final now = DateTime.now();
    if (announcement.status == 'archived') return false;
    if (announcement.startsAt.isAfter(now)) return false;
    final endsAt = announcement.endsAt;
    if (endsAt != null && !endsAt.isAfter(now)) return false;
    return true;
  }

  int _categoryRank(String category) {
    switch (category) {
      case 'urgent':
        return 3;
      case 'reminder':
        return 2;
      default:
        return 1;
    }
  }

  int _priorityRank(String priority) {
    switch (priority) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      default:
        return 1;
    }
  }

  int _boolRank(bool value) => value ? 1 : 0;

  bool _isMissingFunction(PostgrestException error) =>
      error.code == 'PGRST202' ||
      error.message.toLowerCase().contains('could not find the function');

  Future<void> createAnnouncement(Announcement announcement) async {
    final manager = await _requireManagerContext();
    final inserted = await _supabase
        .from('announcements')
        .insert({
          ...announcement.toJson(),
          'condo_id': manager.condoId,
          'posted_by': manager.managerId,
        })
        .select('id')
        .single();

    final announcementId = (inserted['id'] as num?)?.toInt();
    if (announcementId != null) {
      await _pushDispatcher.dispatchAnnouncementPublished(
        announcementId: announcementId,
        condoId: manager.condoId,
      );
    }
  }

  Future<void> updateAnnouncement(
    int id,
    String title,
    String message,
    String category, {
    DateTime? endsAt,
  }) async {
    final manager = await _requireManagerContext();
    await _supabase
        .from('announcements')
        .update({
          'title': title,
          'content': message,
          'category': category,
          'ends_at': endsAt?.toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('condo_id', manager.condoId);
  }

  Future<void> deleteAnnouncement(int id) async {
    final manager = await _requireManagerContext();
    await _supabase
        .from('announcements')
        .delete()
        .eq('id', id)
        .eq('condo_id', manager.condoId);
  }

  Future<String?> getManagerName() async {
    final profile = await _identity.getCurrentProfile();
    if (profile == null) return null;

    final data = await _supabase
        .from('profiles')
        .select('first_name, last_name')
        .eq('id', profile.id)
        .maybeSingle();

    if (data == null) return null;

    final first = data['first_name'] as String? ?? '';
    final last = data['last_name'] as String? ?? '';
    return '$first $last'.trim();
  }

  Future<_ManagerContext> _requireManagerContext() async {
    final profile = await _identity.requireCurrentProfile(
      missingMessage: 'No manager profile is linked to this signed-in user.',
    );

    final manager = await _supabase
        .from('managers')
        .select('id, condo_id')
        .eq('id', profile.id)
        .maybeSingle();

    if (manager == null) {
      throw StateError(
        'Manager account setup is incomplete (missing managers row). Please sign out and complete onboarding again.',
      );
    }

    final condoIdValue = manager['condo_id'];
    final condoId = condoIdValue is int
        ? condoIdValue
        : int.parse(condoIdValue.toString());

    return _ManagerContext(
      managerId: (manager['id'] as String?) ?? profile.id,
      condoId: condoId,
    );
  }
}

class _ManagerContext {
  const _ManagerContext({required this.managerId, required this.condoId});

  final String managerId;
  final int condoId;
}
