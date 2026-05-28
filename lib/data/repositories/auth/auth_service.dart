import 'dart:io';

import 'package:mycondo/config/app_config.dart';
import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:mycondo/services/shared/presence_service.dart';
import 'package:mycondo/services/push/push_notification_service.dart';
import 'package:mycondo/services/push/push_session_binding_service.dart';
import 'package:mycondo/services/shared/session_preference_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileIdentityService _identity = ProfileIdentityService();
  final SessionPreferenceService _sessionPreferenceService =
      SessionPreferenceService();
  final PushSessionBindingService _pushBindingService =
      PushSessionBindingService();
  final PushNotificationService _pushNotificationService =
      PushNotificationService.instance;

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
    final previousProfile = await _identity.getCurrentProfile();
    if (previousProfile != null) {
      await _pushNotificationService.unregisterCurrentProfileDevice(
        profileId: previousProfile.id,
      );
    }

    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    await _sessionPreferenceService.clearOnboardingRetention();
    await _sessionPreferenceService.applyLoginChoice(
      keepSignedIn: keepSignedIn,
    );

    final profileId = response.user?.id ?? _supabase.auth.currentUser?.id;
    if (keepSignedIn && profileId != null && profileId.isNotEmpty) {
      await _pushBindingService.bindPersistentSession(profileId: profileId);
    } else {
      await _pushBindingService.clearBinding();
    }

    await _pushNotificationService.registerCurrentProfileDevice();

    return response;
  }

  //sign out
  Future<void> signOut({bool clearRememberSessionPreference = true}) async {
    final profileId = (await _identity.getCurrentProfile())?.id;

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
        await _sessionPreferenceService.clearOnboardingRetention();
      }
      await _pushNotificationService.unregisterCurrentProfileDevice(
        profileId: profileId,
      );
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

  Future<void> _verifyCurrentPassword({
    required String email,
    required String currentPassword,
  }) async {
    final verifier = SupabaseClient(
      AppConfig.supabaseUrl,
      AppConfig.supabaseAnonKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

    try {
      await _supabase.auth.updateUser(UserAttributes(password: password));
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _supabase.auth.currentUser;
    final email = user?.email?.trim();

    if (email == null || email.isEmpty) {
      throw 'No account email found. Please sign in again.';
    }

    try {
      await _verifyCurrentPassword(
        email: email,
        currentPassword: currentPassword,
      );

      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();

      if (message.contains('invalid login credentials') ||
          message.contains('invalid email or password')) {
        throw 'Current password is incorrect.';
      }

      throw e.message;
    } on SocketException {
      throw 'Cannot connect to Supabase. Check your internet.';
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw e.message;
    } on SocketException {
      throw "Cannot connect to Supabase. Check your internet.";
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> sendRecoveryVerificationPin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw 'No active session found. Please sign in again.';
    }

    final email = (user.email ?? '').trim();
    if (email.isEmpty) {
      throw 'No account email found. Please update your email first.';
    }

    try {
      await _supabase.auth.signInWithOtp(email: email, shouldCreateUser: false);
    } on AuthException catch (e) {
      throw _mapRecoveryOtpMessage(e.message);
    } on SocketException {
      throw "Cannot connect to Supabase. Check your internet.";
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> verifyRecoveryAccountWithPin(String pin) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw 'No active session found. Please sign in again.';
    }

    final email = (user.email ?? '').trim();
    if (email.isEmpty) {
      throw 'No account email found. Please update your email first.';
    }

    final trimmedPin = pin.trim();
    if (trimmedPin.isEmpty) {
      throw 'Enter the verification code sent to your email.';
    }

    final metadata = Map<String, dynamic>.from(user.userMetadata ?? {});
    metadata['recovery_verified'] = true;
    metadata['recovery_verified_at'] = DateTime.now().toUtc().toIso8601String();

    try {
      await _supabase.auth.verifyOTP(
        email: email,
        token: trimmedPin,
        type: OtpType.email,
      );
      await _supabase.auth.updateUser(UserAttributes(data: metadata));
    } on AuthException catch (e) {
      throw _mapRecoveryOtpMessage(e.message);
    } on SocketException {
      throw "Cannot connect to Supabase. Check your internet.";
    } catch (e) {
      throw e.toString();
    }
  }

  String _mapRecoveryOtpMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('token has expired') ||
        normalized.contains('is invalid')) {
      return 'That verification code is invalid or expired. Please request a new code and try again.';
    }
    return message;
  }

  bool isRecoveryAccountVerified() {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    return user.userMetadata?['recovery_verified'] == true;
  }

  Future<void> sendRecoveryEmailForVerifiedAccount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw 'No active session found. Please sign in again.';
    }

    if (!isRecoveryAccountVerified()) {
      throw 'Verify your account in Profile before requesting a recovery email.';
    }

    final email = (user.email ?? '').trim();
    if (email.isEmpty) {
      throw 'No account email found. Please update your profile email first.';
    }

    await sendPasswordResetEmail(email);
  }

  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}
