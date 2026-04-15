import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mycondo/data/models/manager/announcement_models.dart';

class ManagerAnnouncementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Announcement>> getAnnouncements() async {
    final manager = await _requireManagerContext();

    final data = await _supabase
        .from('announcements')
        .select()
        .eq('condo_id', manager.condoId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => Announcement.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> createAnnouncement(Announcement announcement) async {
    final manager = await _requireManagerContext();
    await _supabase.from('announcements').insert({
      ...announcement.toJson(),
      'condo_id': manager.condoId,
      'posted_by': manager.managerId,
    });
  }

  Future<void> updateAnnouncement(
      int id, String title, String message, String category) async {
    final manager = await _requireManagerContext();
    await _supabase.from('announcements').update({
      'title': title,
      'content': message,
      'category': category,
    }).eq('id', id).eq('condo_id', manager.condoId);
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
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _supabase
        .from('profiles')
        .select('first_name, last_name')
        .eq('id', userId)
        .single();

    final first = data['first_name'] as String? ?? '';
    final last = data['last_name'] as String? ?? '';
    return '$first $last'.trim();
  }

  Future<_ManagerContext> _requireManagerContext() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated manager user found.');
    }

    final manager = await _supabase
        .from('managers')
        .select('id, condo_id')
        .eq('id', userId)
        .single();

    final condoIdValue = manager['condo_id'];
    final condoId = condoIdValue is int
        ? condoIdValue
        : int.parse(condoIdValue.toString());

    return _ManagerContext(
      managerId: (manager['id'] as String?) ?? userId,
      condoId: condoId,
    );
  }
}

class _ManagerContext {
  const _ManagerContext({
    required this.managerId,
    required this.condoId,
  });

  final String managerId;
  final int condoId;
}
