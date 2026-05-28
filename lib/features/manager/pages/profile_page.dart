import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mycondo/data/repositories/auth/auth_service.dart';
import 'package:mycondo/data/repositories/manager/manager_profile_service.dart';
import 'package:mycondo/features/shared/widgets/app_about_sheet.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/services/shared/session_timer_service.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/utils/app_snackbar.dart';

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
  bool _isRecoveryVerified = false;
  bool _isRecoveryActionLoading = false;

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
        _isRecoveryVerified = _authService.isRecoveryAccountVerified();
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

  Future<void> _openEditProfileSheet() async {
    final updated = await showModalBottomSheet<_ProfileDetailsUpdate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileSheet(
        firstName: _firstName ?? '',
        lastName: _lastName ?? '',
        email: _email ?? '',
      ),
    );

    if (updated == null) return;

    try {
      await _profileService.updateProfileDetails(
        firstName: updated.firstName,
        lastName: updated.lastName,
      );
      if (!mounted) return;
      setState(() {
        _firstName = updated.firstName;
        _lastName = updated.lastName;
      });
      context.showAppSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } catch (e, st) {
      if (!mounted) return;
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not update your profile.',
        debugLabel: 'ManagerProfilePage.updateProfile',
      );
    }
  }

  Future<void> _openChangePasswordSheet() async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChangePasswordSheet(
        onSubmit: _authService.updatePassword,
        onError: _showPasswordError,
      ),
    );

    if (!mounted || updated != true) return;
    await _showPasswordChangedDialog();
  }

  Future<void> _showPasswordChangedDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password Successfully Changed'),
        content: const Text('Your password has been updated.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Okay'),
          ),
        ],
      ),
    );
  }

  void _showPasswordError(Object error, [StackTrace? stackTrace]) {
    if (!mounted) return;
    context.showAppError(
      error,
      stackTrace: stackTrace,
      fallbackMessage: 'Could not update your password.',
      debugLabel: 'ManagerProfilePage.updatePassword',
    );
  }

  void _openHelpCenter() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _HelpCenterSheet(),
    );
  }

  void _openAboutApp() {
    showAppAboutSheet(context);
  }

  Future<void> _handleRecoveryEmailAction() async {
    if (_isRecoveryActionLoading) return;

    setState(() => _isRecoveryActionLoading = true);
    var verifiedThisRun = false;
    try {
      if (!_isRecoveryVerified) {
        final verified = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _RecoveryPinSheet(
            email: (_email ?? '').trim(),
            onSendCode: _authService.sendRecoveryVerificationPin,
            onVerifyPin: _authService.verifyRecoveryAccountWithPin,
          ),
        );

        if (!mounted || verified != true) return;
        verifiedThisRun = true;
        setState(() => _isRecoveryVerified = true);
      }

      await _authService.sendRecoveryEmailForVerifiedAccount();
      if (!mounted) return;
      context.showAppSnackBar(
        SnackBar(
          content: Text(
            verifiedThisRun
                ? 'Email verified. Recovery email sent.'
                : 'Recovery email sent. Please check your inbox.',
          ),
        ),
      );
    } catch (e, st) {
      if (!mounted) return;
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not complete email verification.',
        debugLabel: 'ManagerProfilePage.handleRecoveryEmailAction',
      );
    } finally {
      if (mounted) {
        setState(() => _isRecoveryActionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = (_email ?? '').trim().isEmpty
        ? 'No email available'
        : _email!;

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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ProfileHeader(
                      name: _displayName,
                      email: email,
                      isRecoveryVerified: _isRecoveryVerified,
                      isRecoveryActionLoading: _isRecoveryActionLoading,
                      onVerifyAccountTap: _handleRecoveryEmailAction,
                    ),
                    const SizedBox(height: 16),
                    const _InfoGrid(),
                    const SizedBox(height: 18),
                    const _SectionLabel('Account'),
                    const SizedBox(height: 10),
                    _ProfileActionTile(
                      title: 'Edit Profile',
                      subtitle: 'Update your name and profile details.',
                      icon: Icons.person_outline_rounded,
                      onTap: _openEditProfileSheet,
                    ),
                    const SizedBox(height: 10),
                    _ProfileActionTile(
                      title: 'Change Password',
                      subtitle: 'Update your login password.',
                      icon: Icons.lock_outline,
                      onTap: _openChangePasswordSheet,
                    ),
                    const SizedBox(height: 16),
                    const _SectionLabel('Management'),
                    const SizedBox(height: 10),
                    _ProfileActionTile(
                      title: 'Condo Profile',
                      subtitle: 'Update condo details, units, and billing.',
                      icon: Icons.apartment_rounded,
                      onTap: () =>
                          Navigator.pushNamed(context, '/manage-condo'),
                    ),
                    const SizedBox(height: 10),
                    _ProfileActionTile(
                      title: 'Residents',
                      subtitle: 'Manage resident profiles and unit access.',
                      icon: Icons.groups_2_outlined,
                      onTap: () =>
                          Navigator.pushNamed(context, '/manage-residents'),
                    ),
                    const SizedBox(height: 10),
                    _ProfileActionTile(
                      title: 'Maintenance Requests',
                      subtitle: 'Review resident repair and issue reports.',
                      icon: Icons.handyman_outlined,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/manager-maintenance-requests',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _SectionLabel('Support'),
                    const SizedBox(height: 10),
                    _ProfileActionTile(
                      title: 'Help Center',
                      subtitle: 'View quick answers and support notes.',
                      icon: Icons.help_outline,
                      onTap: _openHelpCenter,
                    ),
                    const SizedBox(height: 10),
                    _ProfileActionTile(
                      title: 'About the app',
                      subtitle: 'Version, build details, and support notes.',
                      icon: Icons.info_outline_rounded,
                      onTap: _openAboutApp,
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      onPressed: _isSigningOut ? null : _logout,
                      icon: _isSigningOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.logout_rounded, size: 18),
                      label: Text(_isSigningOut ? 'Logging out...' : 'Log out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String get _displayName {
    final firstName = (_firstName ?? '').trim();
    final lastName = (_lastName ?? '').trim();
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Manager' : name;
  }
}

class _RecoveryPinSheet extends StatefulWidget {
  const _RecoveryPinSheet({
    required this.email,
    required this.onSendCode,
    required this.onVerifyPin,
  });

  final String email;
  final Future<void> Function() onSendCode;
  final Future<void> Function(String pin) onVerifyPin;

  @override
  State<_RecoveryPinSheet> createState() => _RecoveryPinSheetState();
}

class _RecoveryPinSheetState extends State<_RecoveryPinSheet> {
  static const int _pinLength = 8;
  static const int _minPinLength = 6;
  late final List<TextEditingController> _digitControllers = List.generate(
    _pinLength,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _digitFocusNodes = List.generate(
    _pinLength,
    (_) => FocusNode(),
  );

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _hasRequestedCode = false;
  bool _isSendingCode = false;
  bool _isVerifying = false;
  String? _errorText;

  String get _displayEmail {
    final trimmed = widget.email.trim();
    return trimmed.isEmpty ? 'your email' : trimmed;
  }

  String get _pinValue =>
      _digitControllers.map((controller) => controller.text).join();

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _digitControllers) {
      controller.dispose();
    }
    for (final node in _digitFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _focusDigit(int index) {
    if (index < 0 || index >= _pinLength) return;
    _digitFocusNodes[index].requestFocus();
  }

  void _clearDigits() {
    for (final controller in _digitControllers) {
      controller.clear();
    }
  }

  void _handleDigitChanged(int index, String rawValue) {
    final value = rawValue.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.isEmpty) {
      _digitControllers[index].clear();
      return;
    }

    if (value.length > 1) {
      var cursor = index;
      for (var i = 0; i < value.length && cursor < _pinLength; i += 1) {
        _digitControllers[cursor].text = value[i];
        _digitControllers[cursor].selection = const TextSelection.collapsed(
          offset: 1,
        );
        cursor += 1;
      }
      if (cursor < _pinLength) {
        _focusDigit(cursor);
      } else {
        _digitFocusNodes.last.unfocus();
      }
      setState(() {});
      return;
    }

    _digitControllers[index].text = value;
    _digitControllers[index].selection = const TextSelection.collapsed(
      offset: 1,
    );
    if (index < _pinLength - 1) {
      _focusDigit(index + 1);
    } else {
      _digitFocusNodes[index].unfocus();
    }
    setState(() {});
  }

  KeyEventResult _handleDigitKey(FocusNode node, int index, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    if (_digitControllers[index].text.isEmpty && index > 0) {
      _digitControllers[index - 1].clear();
      _focusDigit(index - 1);
      setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _sendCode() async {
    if (_isSendingCode) return;
    setState(() {
      _isSendingCode = true;
      _errorText = null;
    });
    try {
      await widget.onSendCode();
      if (!mounted) return;
      setState(() => _hasRequestedCode = true);
      _clearDigits();
      _focusDigit(0);
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  Future<void> _verify() async {
    if (!_hasRequestedCode) {
      setState(() => _errorText = 'Tap "Send code" first.');
      return;
    }
    final pin = _pinValue.trim();
    if (pin.length < _minPinLength || pin.length > _pinLength) {
      setState(
        () => _errorText = 'Enter the verification code from your email.',
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });
    try {
      await widget.onVerifyPin(pin);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStepTwo = _hasRequestedCode;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify Email',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                isStepTwo
                    ? 'Enter the code sent to $_displayEmail:'
                    : 'Verify your email so you can recover your account if you forget your password.',
                style: const TextStyle(color: Color(0xFF66737C), height: 1.3),
              ),
              const SizedBox(height: 14),
              if (isStepTwo) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_pinLength, (index) {
                    return SizedBox(
                      width: 36,
                      child: Focus(
                        onKeyEvent: (node, event) =>
                            _handleDigitKey(node, index, event),
                        child: TextField(
                          controller: _digitControllers[index],
                          focusNode: _digitFocusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          textInputAction: index == _pinLength - 1
                              ? TextInputAction.done
                              : TextInputAction.next,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7FBFF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFD7E6F3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFD7E6F3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.primaryBlue,
                                width: 1.4,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          onChanged: (value) =>
                              _handleDigitChanged(index, value),
                        ),
                      ),
                    );
                  }),
                ),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: isStepTwo
                    ? ElevatedButton(
                        onPressed: _isVerifying ? null : _verify,
                        child: Text(
                          _isVerifying ? 'Verifying...' : 'Verify Pin',
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _isSendingCode ? null : _sendCode,
                        child: Text(
                          _isSendingCode
                              ? 'Sending...'
                              : 'Send Verification Code to Email',
                        ),
                      ),
              ),
              if (isStepTwo) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: (_isSendingCode || _secondsRemaining > 0)
                        ? null
                        : _sendCode,
                    child: Text(
                      _secondsRemaining > 0
                          ? 'Resend Code (${_secondsRemaining}s)'
                          : (_isSendingCode ? 'Sending...' : 'Resend Code'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.isRecoveryVerified,
    required this.isRecoveryActionLoading,
    required this.onVerifyAccountTap,
  });

  final String name;
  final String email;
  final bool isRecoveryVerified;
  final bool isRecoveryActionLoading;
  final Future<void> Function() onVerifyAccountTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3EEF7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFEAF4FB),
                child: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: AppColors.primaryBlue,
                  size: 34,
                ),
              ),
              if (!isRecoveryVerified) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: 104,
                  child: OutlinedButton(
                    onPressed: isRecoveryActionLoading
                        ? null
                        : onVerifyAccountTap,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(34),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      side: const BorderSide(color: Color(0xFFBFD6EA)),
                    ),
                    child: Text(
                      isRecoveryActionLoading
                          ? 'Processing...'
                          : 'Verify Account',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF66737C),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isRecoveryVerified) ...[
                  const SizedBox(height: 8),
                  const _VerifiedBadge(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: Color(0xFF1F8A4C)),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F8A4C),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _InfoTile(
            label: 'Role',
            value: 'Manager',
            icon: Icons.admin_panel_settings_outlined,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _InfoTile(
            label: 'Access',
            value: 'Admin',
            icon: Icons.verified_user_outlined,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _InfoTile(
            label: 'Account',
            value: 'Active',
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 20),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF66737C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Color(0xFF66737C),
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3EEF7)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF1A73C8), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: Color(0xFF66737C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9BA8B2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileDetailsUpdate {
  const _ProfileDetailsUpdate({
    required this.firstName,
    required this.lastName,
  });

  final String firstName;
  final String lastName;
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String firstName;
  final String lastName;
  final String email;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.firstName);
    _lastNameController = TextEditingController(text: widget.lastName);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      _ProfileDetailsUpdate(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email.trim().isEmpty
        ? 'No email available'
        : widget.email.trim();

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 22,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FCFF),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
            bottom: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4DCE4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4FB),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFF1A73C8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Update the name shown in your account.',
                            style: TextStyle(
                              color: Color(0xFF66737C),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _firstNameController,
                  textInputAction: TextInputAction.next,
                  decoration: _profileInputDecoration(
                    label: 'First name',
                    icon: Icons.badge_outlined,
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Enter your first name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  textInputAction: TextInputAction.done,
                  decoration: _profileInputDecoration(
                    label: 'Last name',
                    icon: Icons.badge_outlined,
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Enter your last name.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 12),
                _ReadOnlyProfileField(
                  label: 'Email',
                  value: email,
                  icon: Icons.mail_outline_rounded,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text('Save Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyProfileField extends StatelessWidget {
  const _ReadOnlyProfileField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: _profileInputDecoration(label: label, icon: icon),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF66737C),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.onSubmit, required this.onError});

  final Future<void> Function({
    required String currentPassword,
    required String newPassword,
  })
  onSubmit;
  final void Function(Object error, [StackTrace? stackTrace]) onError;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await widget.onSubmit(
        currentPassword: _currentPasswordController.text,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      widget.onError(e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 22,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FCFF),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
            bottom: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4DCE4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4FB),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF1A73C8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Verify your current password before changing it.',
                            style: TextStyle(
                              color: Color(0xFF66737C),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _PasswordRequirementCard(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscurePassword,
                  decoration: _profileInputDecoration(
                    label: 'Current password',
                    icon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final password = value ?? '';
                    if (password.isEmpty) {
                      return 'Enter your current password.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _profileInputDecoration(
                    label: 'New password',
                    icon: Icons.password_rounded,
                  ),
                  validator: (value) {
                    final password = value ?? '';
                    if (password.length < 6) {
                      return 'Use at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscurePassword,
                  decoration: _profileInputDecoration(
                    label: 'Confirm password',
                    icon: Icons.verified_user_outlined,
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 20),
                    label: Text(_isSaving ? 'Updating...' : 'Update Password'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordRequirementCard extends StatelessWidget {
  const _PasswordRequirementCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF1A73C8)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Use at least 6 characters. Choose something you do not use anywhere else.',
              style: TextStyle(
                color: Color(0xFF35566E),
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpCenterSheet extends StatelessWidget {
  const _HelpCenterSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
            bottom: Radius.circular(20),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help Center',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 14),
            _HelpItem(
              title: 'Payments',
              body:
                  'Use payment approvals to review resident submissions and keep billing records current.',
            ),
            _HelpItem(
              title: 'Residents',
              body:
                  'Manage residents to update access details, unit assignments, and resident records.',
            ),
            _HelpItem(
              title: 'Maintenance',
              body:
                  'Maintenance requests show resident issues that need review, notes, or status updates.',
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(
            body,
            style: const TextStyle(color: Color(0xFF66737C), height: 1.35),
          ),
        ],
      ),
    );
  }
}

InputDecoration _profileInputDecoration({
  required String label,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFF7A8994), size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE1EAF2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFB3261E)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5),
    ),
  );
}
