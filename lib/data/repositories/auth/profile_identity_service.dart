import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileIdentity {
  const ProfileIdentity({
    required this.id,
    required this.authId,
    this.role,
  });

  final String id;
  final String authId;
  final String? role;
}

class ProfileIdentityService {
  ProfileIdentityService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<ProfileIdentity?> getCurrentProfile() async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) return null;

    final data = await _supabase
        .from('profiles')
        .select('id, auth_id, role')
        .eq('auth_id', authId)
        .maybeSingle();

    if (data == null) return null;

    return ProfileIdentity(
      id: data['id'].toString(),
      authId: (data['auth_id'] ?? authId).toString(),
      role: data['role']?.toString(),
    );
  }

  Future<ProfileIdentity> requireCurrentProfile({
    String missingMessage = 'No profile is linked to this signed-in user.',
  }) async {
    final profile = await getCurrentProfile();
    if (profile == null) {
      throw StateError(missingMessage);
    }
    return profile;
  }
}
