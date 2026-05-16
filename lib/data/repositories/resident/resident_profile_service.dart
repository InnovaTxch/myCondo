import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';

class ResidentProfileService {
  final supabase = Supabase.instance.client;
  final ProfileIdentityService _identity = ProfileIdentityService();

  Future<Map<String, dynamic>> getProfile() async {
    final profile = await _identity.requireCurrentProfile(
      missingMessage: 'No resident profile is linked to this signed-in user.',
    );

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', profile.id)
        .single();

    final resident = await supabase
        .from('residents')
        .select('code, status, units(name)')
        .eq('id', profile.id)
        .maybeSingle();

    final unit = resident?['units'] as Map<String, dynamic>?;
    final authEmail = supabase.auth.currentUser?.email?.trim();
    final profileEmail = (data['email'] as String?)?.trim();
    final resolvedEmail =
        (profileEmail != null && profileEmail.isNotEmpty)
            ? profileEmail
            : authEmail;

    return {
      ...data,
      'email': resolvedEmail,
      'resident_code': resident?['code'],
      'resident_status': resident?['status'],
      'unit_name': unit?['name'],
    };
  }

  Future<void> updateProfileDetails({
    required String firstName,
    required String lastName,
  }) async {
    final profile = await _identity.requireCurrentProfile(
      missingMessage: 'No resident profile is linked to this signed-in user.',
    );

    await supabase
        .from('profiles')
        .update({'first_name': firstName.trim(), 'last_name': lastName.trim()})
        .eq('id', profile.id);
  }
}
