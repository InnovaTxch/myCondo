import 'dart:math';

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

      final profileId = profile['id'].toString();

      final code = await _generateCondoCode();

      final condo = await _supabase
          .from('condos')
          .insert({
            'name': input.name.trim(),
            'location': '',
            'description': '',
            'image_url': '',
            'gallery_urls': <String>[],
            'code': code,
          })
          .select('id')
          .single();

      final condoId = condo['id'];

      await _supabase.from('managers').upsert({
        'id': profileId,
        'condo_id': condoId,
      });

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

  Future<String> _generateCondoCode() async {
    bool isUnique = false;
    String code = "";

    while (!isUnique) {
      code = _generateRandomString(8);

      final response = await _supabase
          .from('condos')
          .select('code')
          .eq('code', code)
          .maybeSingle();

      if (response == null) {
        isUnique = true;
      }
    }

    return code;
  }

  String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    Random rnd = Random();

    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
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
