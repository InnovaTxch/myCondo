import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/data/repositories/auth/auth_service.dart';
import 'package:mycondo/data/repositories/resident/resident_profile_service.dart';
import 'package:mycondo/data/repositories/resident/resident_settings_service.dart';
import 'package:mycondo/services/shared/session_timer_service.dart';
import 'package:mycondo/utils/app_snackbar.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';

class ResidentProfilePage extends StatefulWidget {
  const ResidentProfilePage({
    super.key,
    this.onContactAdministration,
    this.onOpenMaintenanceRequests,
  });

  final VoidCallback? onContactAdministration;
  final VoidCallback? onOpenMaintenanceRequests;

  @override
  State<ResidentProfilePage> createState() => _ResidentProfilePageState();
}

class _ResidentProfilePageState extends State<ResidentProfilePage> {
  final AuthService _authService = AuthService();
  final ResidentProfileService _profileService = ResidentProfileService();
  final ResidentSettingsService _settingsService = ResidentSettingsService();

  String? _firstName;
  String? _lastName;
  String? _email;
  String? _unitName;
  String? _residentCode;
  String? _status;
  ResidentNotificationPreferences? _notifications;
  ResidentMessagingPreferences? _messaging;
  List<ResidentPaymentMethod> _paymentMethods = const [];

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
      final profileFuture = _profileService.getProfile();
      final settingsFuture = _settingsService.fetchSettings();
      final email = _authService.getCurrentUserEmail();
      final results = await Future.wait([profileFuture, settingsFuture]);
      final profile = results[0] as Map<String, dynamic>;
      final settings = results[1] as ResidentSettingsBundle;

      if (!mounted) return;

      setState(() {
        _firstName = profile['first_name']?.toString();
        _lastName = profile['last_name']?.toString();
        final profileEmail = profile['email']?.toString().trim();
        final authEmail = email?.trim();
        _email = (profileEmail != null && profileEmail.isNotEmpty)
            ? profileEmail
            : authEmail;
        _unitName = profile['unit_name']?.toString();
        _residentCode = profile['resident_code']?.toString();
        _status = profile['resident_status']?.toString();
        _notifications = settings.notifications;
        _messaging = settings.messaging;
        _paymentMethods = settings.paymentMethods;
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
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (_) {
      if (!mounted) return;

      context.showAppSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );

      setState(() => _isSigningOut = false);
    }
  }

  void _showPasswordError(Object error) {
    if (!mounted) return;
    context.showAppSnackBar(
      SnackBar(content: Text('Could not update password: $error')),
    );
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
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(
        SnackBar(content: Text('Could not update profile: $e')),
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
    context.showAppSnackBar(const SnackBar(content: Text('Password updated.')));
  }

  void _openHelpCenter() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _HelpCenterSheet(),
    );
  }

  Future<void> _openNotificationsSheet() async {
    final settings = _notifications;
    if (settings == null) return;

    final updated = await showModalBottomSheet<ResidentNotificationPreferences>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationSettingsSheet(initial: settings),
    );

    if (updated == null) return;
    await _settingsService.saveNotifications(updated);
    if (!mounted) return;
    setState(() => _notifications = updated);
    context.showAppSnackBar(
      const SnackBar(content: Text('Notification settings updated.')),
    );
  }

  Future<void> _openMessagePreferencesSheet() async {
    final settings = _messaging;
    if (settings == null) return;

    final updated = await showModalBottomSheet<ResidentMessagingPreferences>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MessagePreferencesSheet(initial: settings),
    );

    if (updated == null) return;
    await _settingsService.saveMessaging(updated);
    if (!mounted) return;
    setState(() => _messaging = updated);
    context.showAppSnackBar(
      const SnackBar(content: Text('Message preferences updated.')),
    );
  }

  Future<void> _openPaymentMethodsSheet() async {
    final updated = await showModalBottomSheet<List<ResidentPaymentMethod>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentMethodsSheet(initial: _paymentMethods),
    );

    if (updated == null) return;
    await _settingsService.savePaymentMethods(updated);
    if (!mounted) return;
    setState(() => _paymentMethods = updated);
    context.showAppSnackBar(
      const SnackBar(content: Text('Payment methods updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _displayName;
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
                      name: fullName,
                      email: email,
                      status: _status,
                    ),
                    const SizedBox(height: 16),
                    _InfoGrid(
                      unitName: _unitName,
                      residentCode: _residentCode,
                      status: _status,
                    ),
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
                    const _SectionLabel('Settings'),
                    const SizedBox(height: 10),
                    _ProfileActionTile(
                      title: 'Notifications',
                      subtitle: _notificationsSummary,
                      icon: Icons.notifications_outlined,
                      onTap: _openNotificationsSheet,
                    ),
                    const SizedBox(height: 10),
                    _ProfileActionTile(
                      title: 'Message Preferences',
                      subtitle: _messagingSummary,
                      icon: Icons.tune_rounded,
                      onTap: _openMessagePreferencesSheet,
                    ),
                    const SizedBox(height: 10),
                    _ProfileActionTile(
                      title: 'Payment Methods',
                      subtitle: _paymentMethodsSummary,
                      icon: Icons.account_balance_wallet_outlined,
                      onTap: _openPaymentMethodsSheet,
                    ),
                    const SizedBox(height: 16),
                    const _SectionLabel('Support'),
                    const SizedBox(height: 10),
                    _ProfileActionTile(
                      title: 'Report an Issue',
                      subtitle:
                          'Open maintenance requests and submit a new one.',
                      icon: Icons.warning_amber_outlined,
                      onTap:
                          widget.onOpenMaintenanceRequests ??
                          () => Navigator.pushNamed(
                            context,
                            '/resident-maintenance-request',
                          ),
                    ),
                    const SizedBox(height: 10),
                    _ProfileActionTile(
                      title: 'Contact Administration',
                      subtitle: 'Message your condo manager.',
                      icon: Icons.contact_mail_outlined,
                      onTap: widget.onContactAdministration,
                    ),
                    const SizedBox(height: 10),
                    _ProfileActionTile(
                      title: 'Help Center',
                      subtitle: 'View quick answers and support notes.',
                      icon: Icons.help_outline,
                      onTap: _openHelpCenter,
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
    return name.isEmpty ? 'Resident' : name;
  }

  String get _notificationsSummary {
    final settings = _notifications;
    if (settings == null) {
      return 'Manage alerts for bills, messages, and announcements.';
    }
    final enabled = [
      settings.paymentReminders,
      settings.announcementAlerts,
      settings.maintenanceUpdates,
      settings.messageAlerts,
    ].where((value) => value).length;
    return '$enabled of 4 alerts enabled.';
  }

  String get _messagingSummary {
    final settings = _messaging;
    if (settings == null) return 'Quiet hours and preferred contact settings.';
    final quietHours = settings.quietHoursEnabled
        ? '${settings.quietHoursStart} - ${settings.quietHoursEnd}'
        : 'Off';
    final preferred = settings.preferredContact == 'email' ? 'Email' : 'In-app';
    return 'Contact: $preferred. Quiet hours: $quietHours.';
  }

  String get _paymentMethodsSummary {
    if (_paymentMethods.isEmpty) {
      return 'Add GCash, bank, or cash details.';
    }
    ResidentPaymentMethod? defaultMethod;
    for (final method in _paymentMethods) {
      if (method.isDefault) {
        defaultMethod = method;
        break;
      }
    }
    final label = defaultMethod?.label ?? _paymentMethods.first.label;
    return '${_paymentMethods.length} saved. Default: $label.';
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.status,
  });

  final String name;
  final String email;
  final String? status;

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
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Color(0xFFEAF4FB),
            child: Icon(
              Icons.person_outline_rounded,
              color: AppColors.primaryBlue,
              size: 34,
            ),
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
                const SizedBox(height: 8),
                _RolePill(status: status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({
    required this.unitName,
    required this.residentCode,
    required this.status,
  });

  final String? unitName;
  final String? residentCode;
  final String? status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoTile(
            label: 'Unit',
            value: _display(unitName, fallback: 'Not assigned'),
            icon: Icons.apartment_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoTile(
            label: 'Code',
            value: _display(residentCode, fallback: 'N/A'),
            icon: Icons.badge_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoTile(
            label: 'Status',
            value: _display(status, fallback: 'Active'),
            icon: Icons.verified_user_outlined,
          ),
        ),
      ],
    );
  }

  String _display(String? value, {required String fallback}) {
    final text = (value ?? '').trim();
    return text.isEmpty ? fallback : text;
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

class _RolePill extends StatelessWidget {
  const _RolePill({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final displayStatus = (status ?? '').trim().isEmpty ? 'Resident' : status!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        displayStatus,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A73C8),
        ),
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
  final VoidCallback? onTap;

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

  final Future<void> Function(String password) onSubmit;
  final ValueChanged<Object> onError;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await widget.onSubmit(_passwordController.text);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      widget.onError(e);
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
                            'Create a new password for your account.',
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
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _profileInputDecoration(
                    label: 'New password',
                    icon: Icons.password_rounded,
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

class _NotificationSettingsSheet extends StatefulWidget {
  const _NotificationSettingsSheet({required this.initial});

  final ResidentNotificationPreferences initial;

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  late ResidentNotificationPreferences _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSheetFrame(
      title: 'Notifications',
      subtitle: 'Choose which alerts you want to receive.',
      icon: Icons.notifications_outlined,
      child: Column(
        children: [
          _SettingsSwitchTile(
            title: 'Payment Reminders',
            subtitle: 'Get reminders for upcoming or overdue bills.',
            value: _settings.paymentReminders,
            onChanged: (value) => setState(
              () => _settings = _settings.copyWith(paymentReminders: value),
            ),
          ),
          _SettingsSwitchTile(
            title: 'Announcement Alerts',
            subtitle: 'Stay updated on building notices and announcements.',
            value: _settings.announcementAlerts,
            onChanged: (value) => setState(
              () => _settings = _settings.copyWith(announcementAlerts: value),
            ),
          ),
          _SettingsSwitchTile(
            title: 'Maintenance Updates',
            subtitle: 'Receive changes for your submitted issues.',
            value: _settings.maintenanceUpdates,
            onChanged: (value) => setState(
              () => _settings = _settings.copyWith(maintenanceUpdates: value),
            ),
          ),
          _SettingsSwitchTile(
            title: 'Message Alerts',
            subtitle: 'Get notified when administration messages you.',
            value: _settings.messageAlerts,
            onChanged: (value) => setState(
              () => _settings = _settings.copyWith(messageAlerts: value),
            ),
          ),
        ],
      ),
      onSave: () => Navigator.pop(context, _settings),
    );
  }
}

class _MessagePreferencesSheet extends StatefulWidget {
  const _MessagePreferencesSheet({required this.initial});

  final ResidentMessagingPreferences initial;

  @override
  State<_MessagePreferencesSheet> createState() =>
      _MessagePreferencesSheetState();
}

class _MessagePreferencesSheetState extends State<_MessagePreferencesSheet> {
  late ResidentMessagingPreferences _settings;
  static const _contactOptions = ['in_app', 'email'];
  static const _timeOptions = [
    '06:00',
    '07:00',
    '08:00',
    '09:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
    '22:00',
    '23:00',
  ];

  @override
  void initState() {
    super.initState();
    _settings = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSheetFrame(
      title: 'Message Preferences',
      subtitle: 'Control how and when administration can reach you.',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsSwitchTile(
            title: 'Allow Manager Messages',
            subtitle: 'Receive direct in-app messages from administration.',
            value: _settings.allowManagerMessages,
            onChanged: (value) => setState(
              () => _settings = _settings.copyWith(allowManagerMessages: value),
            ),
          ),
          _SettingsSwitchTile(
            title: 'Quiet Hours',
            subtitle: 'Pause non-urgent message notifications at night.',
            value: _settings.quietHoursEnabled,
            onChanged: (value) => setState(
              () => _settings = _settings.copyWith(quietHoursEnabled: value),
            ),
          ),
          const SizedBox(height: 12),
          const _SheetFieldLabel('Preferred Contact'),
          const SizedBox(height: 8),
          Row(
            children: _contactOptions.map((option) {
              final selected = _settings.preferredContact == option;
              final label = option == 'email' ? 'Email' : 'In-app';
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: option == _contactOptions.first ? 8 : 0,
                  ),
                  child: _SegmentButton(
                    label: label,
                    selected: selected,
                    onTap: () => setState(
                      () => _settings = _settings.copyWith(
                        preferredContact: option,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          if (_settings.quietHoursEnabled) ...[
            const _SheetFieldLabel('Quiet Hours'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SimpleDropdownField(
                    value: _settings.quietHoursStart,
                    items: _timeOptions,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(
                        () => _settings = _settings.copyWith(
                          quietHoursStart: value,
                        ),
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('to'),
                ),
                Expanded(
                  child: _SimpleDropdownField(
                    value: _settings.quietHoursEnd,
                    items: _timeOptions,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(
                        () => _settings = _settings.copyWith(
                          quietHoursEnd: value,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      onSave: () => Navigator.pop(context, _settings),
    );
  }
}

class _PaymentMethodsSheet extends StatefulWidget {
  const _PaymentMethodsSheet({required this.initial});

  final List<ResidentPaymentMethod> initial;

  @override
  State<_PaymentMethodsSheet> createState() => _PaymentMethodsSheetState();
}

class _PaymentMethodsSheetState extends State<_PaymentMethodsSheet> {
  late List<ResidentPaymentMethod> _methods;

  @override
  void initState() {
    super.initState();
    _methods = List<ResidentPaymentMethod>.from(widget.initial);
  }

  void _addMethod() {
    setState(() {
      _methods = [
        ..._methods,
        const ResidentPaymentMethod(
          label: '',
          accountName: '',
          accountNumber: '',
          instructions: '',
          isDefault: false,
        ),
      ];
    });
  }

  void _removeMethod(int index) {
    setState(() {
      final next = List<ResidentPaymentMethod>.from(_methods)..removeAt(index);
      final hasDefault = next.any((method) => method.isDefault);
      _methods = hasDefault || next.isEmpty
          ? next
          : [next.first.copyWith(isDefault: true), ...next.skip(1)];
    });
  }

  void _setDefault(int index) {
    setState(() {
      _methods = _methods.asMap().entries.map((entry) {
        return entry.value.copyWith(isDefault: entry.key == index);
      }).toList();
    });
  }

  void _updateMethod(int index, ResidentPaymentMethod method) {
    final next = List<ResidentPaymentMethod>.from(_methods);
    next[index] = method;
    setState(() => _methods = next);
  }

  void _save() {
    final cleaned = _methods
        .where(
          (method) =>
              method.label.trim().isNotEmpty ||
              method.accountName.trim().isNotEmpty ||
              method.accountNumber.trim().isNotEmpty,
        )
        .map(
          (method) => method.copyWith(
            label: method.label.trim(),
            accountName: method.accountName.trim(),
            accountNumber: method.accountNumber.trim(),
            instructions: '',
          ),
        )
        .toList();

    if (cleaned.any(
      (method) =>
          method.label.isEmpty ||
          method.accountName.isEmpty ||
          method.accountNumber.isEmpty,
    )) {
      context.showAppSnackBar(
        const SnackBar(
          content: Text('Complete each payment method before saving.'),
        ),
      );
      return;
    }

    final withDefault = cleaned.isEmpty
        ? cleaned
        : cleaned.any((method) => method.isDefault)
        ? cleaned
        : [cleaned.first.copyWith(isDefault: true), ...cleaned.skip(1)];

    Navigator.pop(context, withDefault);
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSheetFrame(
      title: 'Payment Methods',
      subtitle: 'Save the payment account details you want to use for bills.',
      icon: Icons.account_balance_wallet_outlined,
      actionLabel: 'Save Methods',
      onSave: _save,
      topAction: OutlinedButton.icon(
        onPressed: _addMethod,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Add Method'),
      ),
      child: _methods.isEmpty
          ? const _EmptySettingsState(
              title: 'No payment methods yet',
              subtitle:
                  'Add GCash, bank transfer, or cash account details here.',
            )
          : Column(
              children: _methods.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PaymentMethodEditorCard(
                    method: entry.value,
                    isOnlyItem: _methods.length == 1,
                    onChanged: (method) => _updateMethod(entry.key, method),
                    onRemove: () => _removeMethod(entry.key),
                    onSetDefault: () => _setDefault(entry.key),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _SettingsSheetFrame extends StatelessWidget {
  const _SettingsSheetFrame({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    required this.onSave,
    this.actionLabel = 'Save Changes',
    this.topAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final VoidCallback onSave;
  final String actionLabel;
  final Widget? topAction;

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
                    child: Icon(icon, color: const Color(0xFF1A73C8)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
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
              if (topAction != null) ...[
                const SizedBox(height: 14),
                topAction!,
              ],
              const SizedBox(height: 16),
              child,
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(actionLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EEF7)),
      ),
      child: Row(
        children: [
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }
}

class _SheetFieldLabel extends StatelessWidget {
  const _SheetFieldLabel(this.text);

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

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : const Color(0xFFE1EAF2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF35566E),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SimpleDropdownField extends StatelessWidget {
  const _SimpleDropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      decoration: _profileInputDecoration(
        label: 'Time',
        icon: Icons.schedule_outlined,
      ),
      onChanged: onChanged,
    );
  }
}

class _EmptySettingsState extends StatelessWidget {
  const _EmptySettingsState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EEF7)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.primaryBlue,
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF66737C),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodEditorCard extends StatefulWidget {
  const _PaymentMethodEditorCard({
    required this.method,
    required this.isOnlyItem,
    required this.onChanged,
    required this.onRemove,
    required this.onSetDefault,
  });

  final ResidentPaymentMethod method;
  final bool isOnlyItem;
  final ValueChanged<ResidentPaymentMethod> onChanged;
  final VoidCallback onRemove;
  final VoidCallback onSetDefault;

  @override
  State<_PaymentMethodEditorCard> createState() =>
      _PaymentMethodEditorCardState();
}

class _PaymentMethodEditorCardState extends State<_PaymentMethodEditorCard> {
  late final TextEditingController _labelController;
  late final TextEditingController _accountNameController;
  late final TextEditingController _accountNumberController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.method.label);
    _accountNameController = TextEditingController(
      text: widget.method.accountName,
    );
    _accountNumberController = TextEditingController(
      text: widget.method.accountNumber,
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  void _emit({bool? isDefault}) {
    widget.onChanged(
      widget.method.copyWith(
        label: _labelController.text,
        accountName: _accountNameController.text,
        accountNumber: _accountNumberController.text,
        instructions: '',
        isDefault: isDefault ?? widget.method.isDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EEF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Payment Method',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: widget.method.isDefault ? null : widget.onSetDefault,
                child: Text(
                  widget.method.isDefault ? 'Default' : 'Set Default',
                ),
              ),
              if (!widget.isOnlyItem)
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          TextField(
            controller: _labelController,
            decoration: _profileInputDecoration(
              label: 'Label',
              icon: Icons.label_outline_rounded,
            ),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _accountNameController,
            decoration: _profileInputDecoration(
              label: 'Account name',
              icon: Icons.person_outline_rounded,
            ),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _accountNumberController,
            decoration: _profileInputDecoration(
              label: 'Account number / reference',
              icon: Icons.confirmation_number_outlined,
            ),
            onChanged: (_) => _emit(),
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
                  'Submitted payments stay pending until management reviews and approves them.',
            ),
            _HelpItem(
              title: 'Maintenance',
              body:
                  'Use Report an Issue for repairs, room concerns, or unit problems.',
            ),
            _HelpItem(
              title: 'Messages',
              body:
                  'Contact Administration opens a direct conversation with your condo manager.',
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
