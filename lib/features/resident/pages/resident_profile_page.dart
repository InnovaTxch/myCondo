import 'package:flutter/material.dart';
import 'package:mycondo/data/repositories/auth/auth_service.dart';
import 'package:mycondo/data/repositories/resident/resident_profile_service.dart';
import 'package:mycondo/services/shared/session_timer_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentProfilePage extends StatefulWidget {
  const ResidentProfilePage({super.key});

  @override
  State<ResidentProfilePage> createState() =>
      _ResidentProfilePageState();
}

class _ResidentProfilePageState extends State<ResidentProfilePage> {
  final AuthService _authService = AuthService();
  final ResidentProfileService _profileService =
  ResidentProfileService();

  String? _firstName;
  String? _lastName;
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
      print(
          "CURRENT USER ID: ${Supabase.instance.client.auth.currentUser?.id}");

      final profile = await _profileService.getProfile();
      final email = _authService.getCurrentUserEmail();

      if (!mounted) return;

      setState(() {
        _firstName = profile['first_name'];
        _lastName = profile['last_name'];
        _email = email;
        _isLoading = false;
      });
    } catch (e) {
      print("RESIDENT PROFILE ERROR: $e");
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
          context, '/login', (route) => false);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not sign out. Please try again.')),
      );

      setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
    (_firstName ?? '').isNotEmpty ? "$_firstName ${_lastName ?? ''}" : 'Resident';

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
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          )
              : ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),

              const SizedBox(height: 16),

              // PROFILE HEADER
              Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Color(0xFFEAEAEA),
                        child: Icon(Icons.person,
                            size: 40, color: Colors.grey),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
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

                  const SizedBox(height: 10),

                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Resident',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6A6A6A),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // MENU LIST
              ...[
                ('Change Password', Icons.lock_outline),
                ('Payment Methods', Icons.wallet_outlined),
                ('Rent Information', Icons.info_outline),
                ('Notifications', Icons.notifications_outlined),
                ('Message Preferences', Icons.chat_bubble_outline),
                ('Documents', Icons.description_outlined),
                ('Help Center', Icons.help_outline),
                ('Report an Issue', Icons.warning_amber_outlined),
                ('Contact Administration', Icons.contact_mail_outlined),
                ('About the app', Icons.info_outline),
              ].map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: ListTile(
                      dense: true, // reduces height

                      visualDensity: const VisualDensity(vertical: -4), // tighter

                      contentPadding: const EdgeInsets.symmetric(

                        horizontal: 16,

                        vertical: 1, // reduce vertical spacing

                      ),

                      leading: Icon(item.$2, size: 20), // slightly smaller icon

                      title: Text(

                        item.$1,

                        style: const TextStyle(fontSize: 14), // smaller text

                      ),

                      trailing: const Icon(Icons.chevron_right, size: 18),

                      shape: RoundedRectangleBorder(

                        borderRadius: BorderRadius.circular(20),

                      ),

                      onTap: () {},

                    )
                  ),
                );
              }),

              const SizedBox(height: 30),

              // LOGOUT
              ElevatedButton(
                onPressed: _isSigningOut ? null : _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}