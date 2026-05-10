import 'package:flutter/foundation.dart';
import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileIdentityService _identity = ProfileIdentityService();

  Future<void> setupManagerAccount(ManagerCondoSetupInput input) async {
    try {
      final authResponse = await _signUpIfNeeded(
        email: input.email,
        password: input.password,
      );
      final authId = authResponse?.user?.id ?? _supabase.auth.currentUser?.id;
      if (authId == null) throw "No user logged in";

      final existingProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('auth_id', authId)
          .maybeSingle();

      final profile = existingProfile ??
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

      if (existingProfile != null) {
        await _supabase.from('profiles').update({
          'first_name': input.firstName.trim(),
          'last_name': input.lastName.trim(),
          'role': 'manager',
        }).eq('id', existingProfile['id']);
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
      await _signUpIfNeeded(
        email: input.email,
        password: input.password,
      );

      await _supabase.rpc(
        'claim_resident_profile',
        params: {
          'p_condo_code': input.condoCode.trim(),
          'p_resident_code': input.residentCode.trim(),
          'p_auth_id': _supabase.auth.currentUser?.id,
        },
      );
      await _identity.requireCurrentProfile();
    } catch (e) {
      debugPrint("Error in setupResidentAccount: $e");
      throw e.toString();
    }
  }

  Future<AuthResponse?> _signUpIfNeeded({
    String? email,
    String? password,
  }) async {
    if (_supabase.auth.currentUser != null) return null;
    if (email == null || email.trim().isEmpty) {
      throw 'Missing signup email. Please sign up again.';
    }
    if (password == null || password.isEmpty) {
      throw 'Missing signup password. Please sign up again.';
    }

    return _supabase.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }


}

class ManagerCondoSetupInput {
  const ManagerCondoSetupInput({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.name,
  });

  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String name;
}

class ResidentClaimInput {
  const ResidentClaimInput({
    required this.email,
    required this.password,
    required this.condoCode,
    required this.residentCode,
  });

  final String email;
  final String password;
  final String condoCode;
  final String residentCode;
}
