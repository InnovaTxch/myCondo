import 'package:mycondo/services/shared/chat_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresenceService {
  PresenceService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final MessagingService _messagingService = MessagingService();

  RealtimeChannel? _channel;

  final Set<String> _onlineProfileIds = {};
  final List<void Function(Set<String>)> _listeners = [];

  Set<String> get onlineProfileIds => Set.unmodifiable(_onlineProfileIds);

  void _notifyListeners() {
    for (final listener in List.of(_listeners)) {
      listener(onlineProfileIds);
    }
  }

  Future<void> start() async {
    final profileId = await _messagingService.currentProfileId;
    if (profileId == null || _channel != null) return;

    final channel = _supabase.channel('online_profiles');
    _channel = channel;

    void syncOnlineProfiles() {
      final activeIds = channel
          .presenceState()
          .expand((state) => state.presences)
          .map((presence) => presence.payload['profile_id']?.toString())
          .whereType<String>()
          .toSet();

      _onlineProfileIds
        ..clear()
        ..addAll(activeIds);

      _notifyListeners();
    }

    channel
        .onPresenceSync((payload) => syncOnlineProfiles())
        .subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await channel.track({
          'profile_id': profileId,
          'online_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    });
  }

  void addListener(void Function(Set<String>) listener) {
    _listeners.add(listener);
    listener(onlineProfileIds);
  }

  void removeListener(void Function(Set<String>) listener) {
    _listeners.remove(listener);
  }

  Future<void> stop() async {
    final channel = _channel;
    if (channel == null) {
      if (_onlineProfileIds.isNotEmpty) {
        _onlineProfileIds.clear();
        _notifyListeners();
      }
      return;
    }

    _channel = null;

    try {
      await channel.untrack();
    } finally {
      await channel.unsubscribe();
      _onlineProfileIds.clear();
      _notifyListeners();
    }
  }
}

final presenceService = PresenceService();
