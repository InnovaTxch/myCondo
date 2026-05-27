import 'dart:io';

import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:mycondo/services/shared/presence_service.dart';
import 'package:mycondo/services/shared/push_session_binding_service.dart';
import 'package:mycondo/services/shared/session_preference_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileIdentityService _identity = ProfileIdentityService();
  final SessionPreferenceService _sessionPreferenceService =
      SessionPreferenceService();
  final PushSessionBindingService _pushBindingService =
      PushSessionBindingService();

  Future<String?> getRole() async {
    try {
      return (await _identity.getCurrentProfile())?.role;
    } catch (_) {
      return null;
    }
  }

  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      // The trigger in the DB handles the profile creation automatically
      return await _supabase.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw e.message;
    } on SocketException {
      throw "Cannot connect to Supabase. Check your internet.";
    } catch (e) {
      throw e.toString();
    }
  }

  //log in with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password, {
    required bool keepSignedIn,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    await _sessionPreferenceService.applyLoginChoice(
      keepSignedIn: keepSignedIn,
    );

    final profileId = response.user?.id ?? _supabase.auth.currentUser?.id;
    if (keepSignedIn && profileId != null && profileId.isNotEmpty) {
      await _pushBindingService.bindPersistentSession(profileId: profileId);
    } else {
      await _pushBindingService.clearBinding();
    }

    return response;
  }

  //sign out
  Future<void> signOut({bool clearRememberSessionPreference = true}) async {
    try {
      await presenceService.stop();
    } catch (_) {
      // Presence cleanup should not block the user from signing out.
    }

    try {
      await _supabase.auth.signOut();
      if (clearRememberSessionPreference) {
        await _sessionPreferenceService.clearRememberedSession();
      } else {
        _sessionPreferenceService.clearEphemeralSessionMarker();
      }
      await _pushBindingService.clearBinding();
    } catch (error, stackTrace) {
      try {
        await presenceService.start();
      } catch (_) {
        // Keep the original auth error visible to the caller.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> updatePassword(String password) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (e) {
      throw e.message;
    } on SocketException {
      throw "Cannot connect to Supabase. Check your internet.";
    } catch (e) {
      throw e.toString();
    }
  }

  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}
