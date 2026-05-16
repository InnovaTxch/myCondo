import 'dart:io';

import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:mycondo/services/shared/presence_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileIdentityService _identity = ProfileIdentityService();

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
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  //sign out
  Future<void> signOut() async {
    try {
      await presenceService.stop();
    } catch (_) {
      // Presence cleanup should not block the user from signing out.
    }

    try {
      await _supabase.auth.signOut();
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
