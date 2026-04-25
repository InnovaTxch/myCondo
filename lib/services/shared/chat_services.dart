import 'package:supabase_flutter/supabase_flutter.dart';

class MessagingService {
  final _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> fetchResidentsForManager(
    String managerId,
  ) async {
    final manager = await _supabase
        .from('managers')
        .select('condo_id')
        .eq('id', managerId)
        .single();

    final condoId = manager['condo_id'];

    final units = await _supabase
        .from('units')
        .select('id')
        .eq('condo_id', condoId);

    final unitIds = (units as List)
        .map((unit) => (unit as Map<String, dynamic>)['id'])
        .toList();

    if (unitIds.isEmpty) return [];

    final residentRows = await _supabase
        .from('residents')
        .select('id, unit_id')
        .inFilter('unit_id', unitIds)
        .eq('status', 'active');

    final residentIds = (residentRows as List)
        .map((resident) => (resident as Map<String, dynamic>)['id'].toString())
        .toList();

    if (residentIds.isEmpty) return [];

    final profiles = await _supabase
        .from('profiles')
        .select('id, first_name, last_name, role')
        .inFilter('id', residentIds);

    return (profiles as List)
        .map((profile) => profile as Map<String, dynamic>)
        .toList();
  }

  Future<Map<String, dynamic>?> fetchResidentManager(String residentId) async {
    final resident = await _supabase
        .from('residents')
        .select('unit_id')
        .eq('id', residentId)
        .maybeSingle();

    if (resident == null) return null;

    final unit = await _supabase
        .from('units')
        .select('condo_id')
        .eq('id', resident['unit_id'])
        .maybeSingle();

    if (unit == null) return null;

    final manager = await _supabase
        .from('managers')
        .select('id, profiles(first_name, last_name)')
        .eq('condo_id', unit['condo_id'])
        .order('created_at')
        .limit(1)
        .maybeSingle();

    if (manager == null) return null;

    final profile = manager['profiles'] as Map<String, dynamic>? ?? {};
    return {
      'id': manager['id'],
      'first_name': profile['first_name'],
      'last_name': profile['last_name'],
      'role': 'manager',
    };
  }

  Future<int> getOrCreateResidentConversation(String residentId) async {
    final manager = await fetchResidentManager(residentId);
    if (manager == null) {
      throw StateError('No manager found for this resident.');
    }

    return getOrCreateConversation(
      managerId: manager['id'].toString(),
      residentId: residentId,
    );
  }

  Future<int> getOrCreateConversation({
    required String managerId,
    required String residentId,
  }) async {
    try {
      final existing = await _supabase
          .from('conversations')
          .select('id')
          .eq('manager_id', managerId)
          .eq('resident_id', residentId)
          .maybeSingle();

      if (existing != null) return existing['id'] as int;

      final newConvo = await _supabase
          .from('conversations')
          .insert({'manager_id': managerId, 'resident_id': residentId})
          .select('id')
          .single();

      return newConvo['id'] as int;
    } catch (_) {
      final fallback = await _supabase
          .from('conversations')
          .select('id')
          .eq('manager_id', managerId)
          .eq('resident_id', residentId)
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
