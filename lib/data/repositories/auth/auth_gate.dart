import 'package:flutter/material.dart';
import 'package:mycondo/data/repositories/auth/auth_service.dart';
import 'package:mycondo/features/auth/pages/login_screen.dart';
import 'package:mycondo/features/manager/pages/dashboard_page.dart';
import 'package:mycondo/features/resident/pages/resident_dashboard.dart';
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
    final authService = AuthService();

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
            future: authService.getRole(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final role = roleSnapshot.data;
              if (role == 'manager') {
                return const ManagerDashboardPage();
              }
              return const ResidentDashboard();
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
