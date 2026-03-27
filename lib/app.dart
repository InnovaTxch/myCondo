import 'package:flutter/material.dart';

import 'features/manager/pages/dashboard_page.dart';
import 'features/manager/widgets/dashboard_models.dart';
import 'features/auth/pages/splash_screen.dart';
import 'features/auth/pages/role_selection.dart';
import 'features/auth/pages/login_screen.dart';
import 'features/auth/pages/signup_screen.dart';
import 'features/resident/pages/tenant_dashboard.dart';

class MyCondoApp extends StatelessWidget {
  const MyCondoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'myCondo',
      debugShowCheckedModeBanner: false,

      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/role': (context) => const RoleSelection(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          final role = settings.arguments as String? ?? 'tenant';

          return MaterialPageRoute<void>(
            builder: (context) {
              if (role == 'manager') {
                return const ManagerDashboardPage(
                  managerName: '',
                  summary: DashboardSummary(
                    totalTenants: null,
                    pendingReports: null,
                    paymentsToReview: null,
                    completionPercent: null,
                  ),
                  announcements: [],
                  quickActions: [],
                  navigationItems: [],
                  selectedNavigationIndex: 0,
                );
              }

              return const TenantDashboard();
            },
            settings: settings,
          );
        }

        return null;
      },
    );
  }
}
