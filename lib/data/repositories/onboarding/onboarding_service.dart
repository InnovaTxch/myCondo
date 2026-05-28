import 'package:flutter/foundation.dart';
import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileIdentityService _identity = ProfileIdentityService();

  Future<void> setupManagerAccount(ManagerCondoSetupInput input) async {
    try {
      final authId = _requireAuthenticatedUserId();

      final existingProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('auth_id', authId)
          .maybeSingle();

      if (existingProfile == null) {
        await _supabase
            .from('profiles')
            .insert({
              'auth_id': authId,
              'first_name': input.firstName.trim(),
              'last_name': input.lastName.trim(),
              'role': 'manager',
            })
            .select('id')
            .single();
      } else {
        await _supabase
            .from('profiles')
            .update({
              'first_name': input.firstName.trim(),
              'last_name': input.lastName.trim(),
              'role': 'manager',
            })
            .eq('id', existingProfile['id']);
      }

      await _supabase.rpc(
        'setup_manager_condo',
        params: {
          'p_name': input.name.trim(),
          'p_location': '',
          'p_description': '',
          'p_image_url': '',
          'p_gallery_urls': <String>[],
        },
      );
    } catch (e) {
      debugPrint("Error in setupManagerAccount: $e");
      throw e.toString();
    }
  }

  Future<void> setupResidentAccount(ResidentClaimInput input) async {
    try {
      final authId = _requireAuthenticatedUserId();

      await _supabase.rpc(
        'claim_resident_profile',
        params: {
          'p_condo_code': input.condoCode.trim(),
          'p_resident_code': input.residentCode.trim(),
          'p_auth_id': authId,
        },
      );
      await _identity.requireCurrentProfile();
    } catch (e) {
      debugPrint("Error in setupResidentAccount: $e");
      throw e.toString();
    }
  }

  String _requireAuthenticatedUserId() {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null || authId.isEmpty) {
      throw 'Your signup session expired. Please sign in again to continue onboarding.';
    }
    return authId;
  }
}

class ManagerCondoSetupInput {
  const ManagerCondoSetupInput({
    required this.firstName,
    required this.lastName,
    required this.name,
  });

  final String firstName;
  final String lastName;
  final String name;
}

class ResidentClaimInput {
  const ResidentClaimInput({
    required this.condoCode,
    required this.residentCode,
  });

  final String condoCode;
  final String residentCode;
}
