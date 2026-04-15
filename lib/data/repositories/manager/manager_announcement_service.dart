import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mycondo/data/models/manager/announcement_models.dart';

class ManagerAnnouncementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Announcement>> getAnnouncements() async {
    final data = await _supabase
        .from('announcements')
        .select()
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => Announcement.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> createAnnouncement(Announcement announcement) async {
    await _supabase.from('announcements').insert(announcement.toJson());
  }

  Future<void> updateAnnouncement(
      String id, String title, String message, String category) async {
    await _supabase.from('announcements').update({
      'title': title,
      'message': message,
      'category': category,
    }).eq('id', id);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _supabase.from('announcements').delete().eq('id', id);
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
}