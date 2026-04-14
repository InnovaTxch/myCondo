import 'package:supabase_flutter/supabase_flutter.dart';

class MessagingService {
  final _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // inbox

  Future<List<Map<String, dynamic>>> fetchOtherUsers(String myId) {
    return _supabase
        .from('profiles')
        .select('id, first_name, last_name, role')
        .neq('id', myId);
  }

  Future<int> getOrCreateConversation(String myId, String otherId) async {
    try {
      final existing = await _supabase
          .from('conversations')
          .select('id')
          .or('and(manager_id.eq.$myId,resident_id.eq.$otherId),'
              'and(manager_id.eq.$otherId,resident_id.eq.$myId)')
          .maybeSingle();

      if (existing != null) return existing['id'] as int;

      final newConvo = await _supabase
          .from('conversations')
          .insert({'manager_id': myId, 'resident_id': otherId})
          .select('id')
          .single();

      return newConvo['id'] as int;
    } catch (_) {
      final fallback = await _supabase
          .from('conversations')
          .select('id')
          .or('and(manager_id.eq.$myId,resident_id.eq.$otherId),'
              'and(manager_id.eq.$otherId,resident_id.eq.$myId)')
          .limit(1)
          .single();
      return fallback['id'] as int;
    }
  }

  // chat

  Stream<List<Map<String, dynamic>>> messagesStream(int conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false);
  }

  Future<void> sendMessage({
    required int conversationId,
    required String content,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'content': content,
    });

    await _supabase.from('conversations').update({
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
  }
}