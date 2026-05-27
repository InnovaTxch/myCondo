import 'package:shared_preferences/shared_preferences.dart';

/// Local placeholder for device/profile push-token association metadata.
///
/// Real push providers (FCM/APNs) can later use this service as the single
/// place to persist and clear device-session binding intent.
class PushSessionBindingService {
  static const String _profileIdKey = 'push.bound_profile_id';
  static const String _persistentKey = 'push.bound_persistent';
  static const String _boundAtKey = 'push.bound_at_iso';

  Future<void> bindPersistentSession({required String profileId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileIdKey, profileId);
    await prefs.setBool(_persistentKey, true);
    await prefs.setString(
      _boundAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<void> clearBinding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileIdKey);
    await prefs.remove(_persistentKey);
    await prefs.remove(_boundAtKey);
  }

  Future<PushSessionBinding?> getBinding() async {
    final prefs = await SharedPreferences.getInstance();
    final profileId = prefs.getString(_profileIdKey);
    if (profileId == null || profileId.trim().isEmpty) {
      return null;
    }

    final persistent = prefs.getBool(_persistentKey) ?? false;
    final boundAtRaw = prefs.getString(_boundAtKey);
    final boundAt = boundAtRaw == null ? null : DateTime.tryParse(boundAtRaw);

    return PushSessionBinding(
      profileId: profileId,
      isPersistent: persistent,
      boundAt: boundAt,
    );
  }
}

class PushSessionBinding {
  const PushSessionBinding({
    required this.profileId,
    required this.isPersistent,
    this.boundAt,
  });

  final String profileId;
  final bool isPersistent;
  final DateTime? boundAt;
}
