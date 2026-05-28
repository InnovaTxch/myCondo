import 'package:flutter/material.dart';
import 'package:mycondo/data/repositories/auth/auth_service.dart';
import 'package:mycondo/features/auth/pages/login_screen.dart';
import 'package:mycondo/features/manager/pages/manager_home_screen.dart';
import 'package:mycondo/features/resident/pages/resident_home_screen.dart';
import 'package:mycondo/features/shared/pages/onboarding_page.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/services/shared/session_preference_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/*
AUTH GATE: This will continuously listen for auth state changes
  unauthenticated ->  Login Screen
  authenticated -> Dashboard
*/

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final auth = Supabase.instance.client.auth;
  final AuthService authService = AuthService();
  final SessionPreferenceService _sessionPreferenceService =
      SessionPreferenceService();

  late final Future<void> _startupSessionFuture;
  String? _roleUserId;
  Future<String?>? _roleFuture;

  @override
  void initState() {
    super.initState();
    _startupSessionFuture = _handleStartupSessionPolicy();
  }

  Future<String?> _getRoleForSession(Session session) {
    final userId = session.user.id;
    final cachedRoleFuture = _roleFuture;
    if (_roleUserId == userId && cachedRoleFuture != null) {
      return cachedRoleFuture;
    }

    _roleUserId = userId;
    return _roleFuture = authService.getRole();
  }

  void _clearRoleCache() {
    _roleUserId = null;
    _roleFuture = null;
  }

  Future<void> _handleStartupSessionPolicy() async {
    final session = auth.currentSession;
    if (session == null) {
      _sessionPreferenceService.clearEphemeralSessionMarker();
      await _sessionPreferenceService.clearOnboardingRetention();
      return;
    }

    final shouldRetain = await _sessionPreferenceService
        .shouldRetainSessionOnAppLaunch();
    if (shouldRetain) {
      return;
    }

    final role = await authService.getRole();
    if (role == 'unassigned') {
      await _sessionPreferenceService.retainSessionForOnboarding();
      return;
    }
    if (role == null) {
      return;
    }

    await authService.signOut(clearRememberSessionPreference: false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupSessionFuture,
      builder: (context, startupSnapshot) {
        if (startupSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: AppLoadingState());
        }

        return StreamBuilder<AuthState>(
          stream: auth.onAuthStateChange,
          initialData: AuthState(
            AuthChangeEvent.initialSession,
            auth.currentSession,
          ),
          builder: (context, snapshot) {
            final session = snapshot.data?.session;

            if (session != null) {
              return FutureBuilder<String?>(
                future: _getRoleForSession(session),
                builder: (context, roleSnapshot) {
                  if (roleSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: AppLoadingState());
                  }

                  final role = roleSnapshot.data;
                  if (role == 'manager') {
                    return const ManagerHomeScreen();
                  }
                  if (role == 'resident') {
                    return const ResidentHomeScreen();
                  }
                  if (role == 'unassigned') {
                    return const OnboardingPage();
                  }
                  return const OnboardingPage();
                },
              );
            } else {
              _clearRoleCache();
              return const LoginScreen();
            }
          },
        );
      },
    );
  }
}
