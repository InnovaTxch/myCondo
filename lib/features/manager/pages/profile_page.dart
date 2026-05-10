import 'package:flutter/material.dart';
import 'package:mycondo/data/repositories/auth/auth_service.dart';
import 'package:mycondo/data/repositories/manager/manager_dashboard_service.dart';
import 'package:mycondo/services/shared/session_timer_service.dart';
import 'package:mycondo/utils/app_snackbar.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';

class ManagerProfilePage extends StatefulWidget {
  const ManagerProfilePage({super.key});

  @override
  State<ManagerProfilePage> createState() => _ManagerProfilePageState();
}

class _ManagerProfilePageState extends State<ManagerProfilePage> {
  final AuthService _authService = AuthService();
  final ManagerDashboardService _dashboardService = ManagerDashboardService();

  String? _firstName;
  String? _email;

  bool _isLoading = true;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile({bool showLoading = true}) async {
    setState(() => _isLoading = showLoading);

    try {
      final firstName = await _dashboardService.getFirstName();
      final email = _authService.getCurrentUserEmail();

      if (!mounted) return;

      setState(() {
        _firstName = firstName;
        _email = email;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _isSigningOut = true);

    try {
      await _authService.signOut();
      SessionTimerService().stopTimer();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      context.showAppSnackBar(
        const SnackBar(content: Text('Could not log out.')),
      );

      setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
    (_firstName ?? '').isNotEmpty ? _firstName! : 'Manager';

    final email =
    (_email ?? '').isNotEmpty ? _email! : 'No email available';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadProfile(showLoading: false),
          child: _isLoading
              ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.65,
                child: const AppLoadingState(),
              ),
            ],
          )
              : ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 16),

              // PROFILE HEADER
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Color(0xFFEAEAEA),
                        child: Icon(Icons.person,
                            size: 40, color: Colors.grey),
                      ),
                      Positioned(
                        top: -4,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.edit,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Manager',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6A6A6A),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // MENU LIST
              ...[
                ('Edit Profile', Icons.person_outline),
                ('Change Password', Icons.lock_outline),
                ('Notifications', Icons.notifications_outlined),
                ('Documents', Icons.description_outlined),
                ('Help Center', Icons.help_outline),
                ('Report an Issue', Icons.warning_amber_outlined),
                ('Contact Administration', Icons.contact_mail_outlined),
                ('About the app', Icons.info_outline),
              ].map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: ListTile(
                      dense: true,
                      visualDensity:
                      const VisualDensity(vertical: -4),
                      contentPadding:
                      const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      leading: Icon(item.$2, size: 20),
                      title: Text(
                        item.$1,
                        style:
                        const TextStyle(fontSize: 14),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          size: 18),
                      onTap: () {},
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // LOGOUT
              ElevatedButton(
                onPressed: _isSigningOut ? null : _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBF2F2F),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isSigningOut
                    ? const CircularProgressIndicator(
                    color: Colors.white)
                    : const Text('LOGOUT'),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
