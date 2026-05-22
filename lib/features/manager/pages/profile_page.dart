import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/data/repositories/auth/auth_service.dart';
import 'package:mycondo/data/repositories/manager/manager_profile_service.dart';
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
  final ManagerProfileService _profileService = ManagerProfileService();

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
      final profile = await _profileService.getProfile();

      if (!mounted) return;

      setState(() {
        _firstName = profile['first_name']?.toString();
        _lastName = profile['last_name']?.toString();
        final profileEmail = profile['email']?.toString().trim();
        final authEmail = _authService.getCurrentUserEmail()?.trim();
        _email = (profileEmail != null && profileEmail.isNotEmpty)
            ? profileEmail
            : authEmail;
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not load your profile right now.',
        debugLabel: 'ManagerProfilePage.loadProfile',
      );
    }
  }

  Future<void> _logout() async {
    setState(() => _isSigningOut = true);

    try {
      await _authService.signOut();
      SessionTimerService().stopTimer();

      if (!mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e, st) {
      if (!mounted) return;
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not log out. Please try again.',
        debugLabel: 'ManagerProfilePage.logout',
      );

      setState(() => _isSigningOut = false);
    }
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.pushNamed(context, '/manager-edit-profile');
    if (!mounted || updated != true) return;
    await _loadProfile(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    final fullName = [
      (_firstName ?? '').trim(),
      (_lastName ?? '').trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    final name = fullName.isNotEmpty ? fullName : 'Manager';

    final email = (_email ?? '').isNotEmpty ? _email! : 'No email available';

    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
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
                              backgroundColor: AppColors.softGray,
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            Positioned(
                              top: -4,
                              right: 0,
                              child: Material(
                                color: AppColors.primaryBlue,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: _openEditProfile,
                                  customBorder: const CircleBorder(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: AppColors.pureWhite,
                                    ),
                                  ),
                                ),
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
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softLavender,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Manager',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
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
                          color: AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(20),
                          child: ListTile(
                            dense: true,
                            visualDensity: const VisualDensity(vertical: -4),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            leading: Icon(item.$2, size: 20),
                            title: Text(
                              item.$1,
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 18),
                            onTap: item.$1 == 'Edit Profile'
                                ? _openEditProfile
                                : null,
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // LOGOUT
                    ElevatedButton(
                      onPressed: _isSigningOut ? null : _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        foregroundColor: AppColors.pureWhite,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isSigningOut
                          ? const CircularProgressIndicator(
                              color: AppColors.pureWhite,
                            )
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
