import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:mycondo/services/push/push_event_dispatcher_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagingService {
  final _supabase = Supabase.instance.client;
  final _identity = ProfileIdentityService();
  final _pushDispatcher = PushEventDispatcherService();

  Future<String?> get currentProfileId async {
    return (await _identity.getCurrentProfile())?.id;
  }

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

  // ── chat ──────────────────────────────────────────────────────────────────

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
    final profile = await _identity.requireCurrentProfile();

    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': profile.id,
      'content': content,
    });

    await _supabase
        .from('conversations')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);

    await _pushDispatcher.dispatchMessageSent(
      conversationId: conversationId,
      senderId: profile.id,
    );
  }

  String _conversationOwnerColumn(String? role) {
    if (role == 'manager') return 'manager_id';
    if (role == 'resident') return 'resident_id';
    throw StateError('Unsupported profile role.');
  }

  String _lastReadColumn(String? role) {
    if (role == 'manager') return 'manager_last_read_at';
    if (role == 'resident') return 'resident_last_read_at';
    throw StateError('Unsupported profile role.');
  }

  Future<bool> _hasUnreadMessagesForCurrentProfile() async {
    final profile = await _identity.requireCurrentProfile();
    final ownerColumn = _conversationOwnerColumn(profile.role);
    final readColumn = _lastReadColumn(profile.role);

    final conversations = await _supabase
        .from('conversations')
        .select('id, $readColumn')
        .eq(ownerColumn, profile.id);

    for (final row in conversations as List<dynamic>) {
      final conversation = row as Map<String, dynamic>;
      final lastReadAt = conversation[readColumn]?.toString();

      final unreadMessages = lastReadAt == null
          ? await _supabase
                .from('messages')
                .select('id')
                .eq('conversation_id', conversation['id'])
                .neq('sender_id', profile.id)
                .limit(1)
          : await _supabase
                .from('messages')
                .select('id')
                .eq('conversation_id', conversation['id'])
                .neq('sender_id', profile.id)
                .gt('created_at', lastReadAt)
                .limit(1);

      if ((unreadMessages as List<dynamic>).isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  Stream<bool> hasUnreadMessagesStream() async* {
    final profile = await _identity.requireCurrentProfile();
    final ownerColumn = _conversationOwnerColumn(profile.role);

    yield await _hasUnreadMessagesForCurrentProfile();

    yield* _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .eq(ownerColumn, profile.id)
        .asyncMap((_) => _hasUnreadMessagesForCurrentProfile())
        .distinct();
  }

  Future<void> markConversationRead(int conversationId) async {
    final profile = await _identity.requireCurrentProfile();
    final readColumn = _lastReadColumn(profile.role);

    await _supabase
        .from('conversations')
        .update({readColumn: DateTime.now().toUtc().toIso8601String()})
        .eq('id', conversationId);
  }

  Future<DateTime?> currentUserLastReadAt(int conversationId) async {
    final profile = await _identity.requireCurrentProfile();
    final readColumn = _lastReadColumn(profile.role);

    final row = await _supabase
        .from('conversations')
        .select(readColumn)
        .eq('id', conversationId)
        .maybeSingle();

    final value = row?[readColumn];
    return value == null ? null : DateTime.tryParse(value.toString());
  }

  Future<Set<String>> fetchManagerUnreadResidentIds(String managerId) async {
    final conversations = await _supabase
        .from('conversations')
        .select('id, resident_id, manager_last_read_at')
        .eq('manager_id', managerId);

    final unreadResidentIds = <String>{};

    for (final raw in conversations as List<dynamic>) {
      final conversation = raw as Map<String, dynamic>;
      final lastReadAt = conversation['manager_last_read_at']?.toString();

      final unreadMessages = lastReadAt == null
          ? await _supabase
                .from('messages')
                .select('id')
                .eq('conversation_id', conversation['id'])
                .neq('sender_id', managerId)
                .limit(1)
          : await _supabase
                .from('messages')
                .select('id')
                .eq('conversation_id', conversation['id'])
                .neq('sender_id', managerId)
                .gt('created_at', lastReadAt)
                .limit(1);

      if ((unreadMessages as List<dynamic>).isNotEmpty) {
        unreadResidentIds.add(conversation['resident_id'].toString());
      }
    }

    return unreadResidentIds;
  }

  Stream<Set<String>> managerUnreadResidentIdsStream(String managerId) async* {
    yield await fetchManagerUnreadResidentIds(managerId);

    yield* _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .eq('manager_id', managerId)
        .asyncMap((_) => fetchManagerUnreadResidentIds(managerId));
  }

  // ── payment notifications ─────────────────────────────────────────────────

  /// For the MANAGER: emits true when there are pending payments awaiting
  /// approval from residents in their condo.
  Stream<bool> hasPendingPaymentsStream() async* {
    final profile = await _identity.requireCurrentProfile();

    // Resolve condo's resident IDs so we only watch relevant payments.
    final residentIds = await _getResidentIdsForManager(profile.id);
    if (residentIds.isEmpty) {
      yield false;
      return;
    }

    yield await _hasPendingPayments(residentIds);

    yield* _supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .asyncMap((_) => _hasPendingPayments(residentIds))
        .distinct();
  }

  Future<bool> _hasPendingPayments(List<String> residentIds) async {
    final rows = await _supabase
        .from('payments')
        .select('id')
        .inFilter('paid_by', residentIds)
        .eq('status', 'pending')
        .limit(1);

    return (rows as List).isNotEmpty;
  }

  Future<List<String>> _getResidentIdsForManager(String managerId) async {
    final manager = await _supabase
        .from('managers')
        .select('condo_id')
        .eq('id', managerId)
        .maybeSingle();

    if (manager == null) return [];

    final units = await _supabase
        .from('units')
        .select('id')
        .eq('condo_id', manager['condo_id']);

    final unitIds = (units as List)
        .map((u) => (u as Map<String, dynamic>)['id'])
        .toList();

    if (unitIds.isEmpty) return [];

    final residents = await _supabase
        .from('residents')
        .select('id')
        .inFilter('unit_id', unitIds)
        .eq('status', 'active');

    return (residents as List)
        .map((r) => (r as Map<String, dynamic>)['id'].toString())
        .toList();
  }

  /// For the RESIDENT: emits true when any of their payments have been
  /// approved or rejected since they last checked (i.e. status != pending).
  /// Call [clearPaymentStatusNotification] once the resident opens the
  /// Payments tab to reset the badge.
  Stream<bool> hasPaymentStatusUpdateStream() async* {
    final profile = await _identity.requireCurrentProfile();

    yield await _hasUnseenPaymentStatusUpdate(profile.id);

    yield* _supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('paid_by', profile.id)
        .asyncMap((_) => _hasUnseenPaymentStatusUpdate(profile.id))
        .distinct();
  }

  Future<bool> _hasUnseenPaymentStatusUpdate(String residentId) async {
    final rows = await _supabase
        .from('payments')
        .select('id, status, payment_seen_by_resident')
        .eq('paid_by', residentId)
        .inFilter('status', ['completed', 'rejected'])
        .eq('payment_seen_by_resident', false)
        .limit(1);

    return (rows as List).isNotEmpty;
  }

  /// Call this when the resident navigates to the Payments tab so the badge
  /// is cleared. It marks all their processed payments as seen.
  Future<void> clearPaymentStatusNotification() async {
    final profile = await _identity.requireCurrentProfile();

    await _supabase
        .from('payments')
        .update({'payment_seen_by_resident': true})
        .eq('paid_by', profile.id)
        .inFilter('status', ['completed', 'rejected'])
        .eq('payment_seen_by_resident', false);
  }
}
