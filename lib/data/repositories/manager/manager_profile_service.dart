import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerProfileService {
  ManagerProfileService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final ProfileIdentityService _identity = ProfileIdentityService();

  Future<Map<String, dynamic>> getProfile() async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) {
      throw StateError('No signed-in user found.');
    }

    final profile = await _identity.requireCurrentProfile(
      missingMessage: 'No manager profile is linked to this signed-in user.',
    );

    final data = await _supabase
        .from('profiles')
        .select('first_name, last_name')
        .eq('id', profile.id)
        .eq('auth_id', authId)
        .single();

    final authEmail = _supabase.auth.currentUser?.email?.trim();

    return {
      ...data,
      'email': authEmail,
    };
  }

  Future<void> updateProfileDetails({
    required String firstName,
    required String lastName,
  }) async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) {
      throw StateError('No signed-in user found.');
    }

    final profile = await _identity.requireCurrentProfile(
      missingMessage: 'No manager profile is linked to this signed-in user.',
    );

    await _supabase
        .from('profiles')
        .update({
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
        })
        .eq('id', profile.id)
        .eq('auth_id', authId)
        .select('id')
        .single();
  }
}
