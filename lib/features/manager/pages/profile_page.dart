import 'package:flutter/material.dart';
import 'package:mycondo/data/repositories/auth/auth_service.dart';
import 'package:mycondo/data/repositories/manager/manager_dashboard_service.dart';

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
  bool _isLoadingProfile = true;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final firstName = await _dashboardService.getFirstName();
      final email = _authService.getCurrentUserEmail();
      if (!mounted) return;
      setState(() {
        _firstName = firstName;
        _email = email;
        _isLoadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _isSigningOut = true);
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sign out. Please try again.')),
      );
      setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _firstName?.trim().isNotEmpty == true ? _firstName! : 'Manager';
    final email = _email?.trim().isNotEmpty == true ? _email! : 'No email available';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _isLoadingProfile
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6A6A6A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Role: Manager',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSigningOut ? null : _logout,
                        icon: _isSigningOut
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.logout_rounded),
                        label: Text(_isSigningOut ? 'Logging out...' : 'Log out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBF2F2F),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
        ),
      ),
    );
  }
}
