import 'package:flutter/material.dart';
import 'package:mycondo/features/auth/pages/login_screen.dart';
import 'package:mycondo/features/shared/pages/dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/*
AUTH GATE: This will continuously listen for auth state changes
  unauthenticated ->  Login Screen
  authenticated -> Dashboard
*/

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;

    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        if (session != null) {
          return Dashboard();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
