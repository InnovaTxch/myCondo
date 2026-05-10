import 'package:flutter/material.dart';
import 'package:mycondo/utils/app_snackbar.dart';

import 'package:mycondo/data/repositories/auth/auth_service.dart';
import 'package:mycondo/data/repositories/auth/pending_signup_credentials.dart';
import 'package:mycondo/data/repositories/onboarding/onboarding_service.dart';

import 'package:mycondo/features/shared/widgets/input_field.dart';
import 'package:mycondo/features/shared/widgets/role_card.dart';
import 'package:mycondo/features/shared/widgets/submit_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final AuthService _authService = AuthService();
  final OnboardingService _service = OnboardingService();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _condoNameController = TextEditingController();
  final _condoCodeController = TextEditingController();
  final _residentCodeController = TextEditingController();

  String _selectedRole = 'manager';
  bool _isLoading = false;

  bool get _isManager => _selectedRole == 'manager';

  void _handleFinalSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isManager) {
        await _service.setupManagerAccount(
          ManagerCondoSetupInput(
            email: _pendingCredentials?.email ?? '',
            password: _pendingCredentials?.password ?? '',
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            name: _condoNameController.text,
          ),
        );
      } else {
        await _service.setupResidentAccount(
          ResidentClaimInput(
            email: _pendingCredentials?.email ?? '',
            password: _pendingCredentials?.password ?? '',
            condoCode: _condoCodeController.text,
            residentCode: _residentCodeController.text,
          ),
        );
      }

      if (!mounted) return;
      PendingSignupStore.clear();

      Navigator.pushReplacementNamed(
        context,
        _isManager ? '/manager-dashboard' : '/resident-dashboard',
      );
    } catch (e) {
      if (mounted) {
        context.showAppSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(() => setState(() {}));
    _lastNameController.addListener(() => setState(() {}));
    _condoNameController.addListener(() => setState(() {}));
    _condoCodeController.addListener(() => setState(() {}));
    _residentCodeController.addListener(() => setState(() {}));
  }

  void _selectRole(String role) {
    if (_selectedRole == role) return;

    setState(() {
      _selectedRole = role;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      if (mounted) {
        context.showAppSnackBar(
          SnackBar(
            content: Text("Error signing out: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _condoNameController.dispose();
    _condoCodeController.dispose();
    _residentCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _handleSignOut,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text("Sign out"),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isManager ? "Set up your condo" : "Join your condo",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _isManager
                    ? "Create your condo workspace and add resident profiles after setup."
                    : "Use the BH code and resident code from your manager.",
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.6),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 32),

              RoleCard(
                title: "I am a Manager",
                description: "I manage units, tenants, bills, and payments.",
                icon: Icons.admin_panel_settings_outlined,
                isSelected: _isManager,
                onTap: () => _selectRole('manager'),
              ),
              const SizedBox(height: 14),
              RoleCard(
                title: "I am a Resident",
                description: "I have a BH code and resident code.",
                icon: Icons.home_work_outlined,
                isSelected: _selectedRole == 'resident',
                onTap: () => _selectRole('resident'),
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Column(
                    key: ValueKey(_selectedRole),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _isManager
                        ? _buildManagerFields()
                        : _buildResidentFields(),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SubmitButton(
                text: _isManager ? "Start Managing" : "Join Condo",
                onPressed: _canSubmit ? _handleFinalSubmit : null,
                color: Color(0xFF5DA9E9),
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSubmit {
    if (_isManager) {
      return _firstNameController.text.trim().isNotEmpty &&
          _lastNameController.text.trim().isNotEmpty &&
          _condoNameController.text.trim().isNotEmpty;
    }

    return _condoCodeController.text.trim().isNotEmpty &&
        _residentCodeController.text.trim().isNotEmpty;
  }

  List<Widget> _buildManagerFields() {
    return [
      _FieldLabel("First Name"),
      InputField(
        hint: "Enter your first name",
        controller: _firstNameController,
        validator: (value) {
          if (_selectedRole == 'manager' && (value ?? '').trim().isEmpty) {
            return 'First name is required';
          }
          return null;
        },
      ),
      const SizedBox(height: 18),
      _FieldLabel("Last Name"),
      InputField(
        hint: "Enter your last name",
        controller: _lastNameController,
        validator: (value) {
          if (_selectedRole == 'manager' && (value ?? '').trim().isEmpty) {
            return 'Last name is required';
          }
          return null;
        },
      ),
      const SizedBox(height: 18),
      _FieldLabel("Condominium Name"),
      InputField(
        hint: "e.g. Blue Residences",
        controller: _condoNameController,
        validator: (value) {
          if (_selectedRole == 'manager' && (value ?? '').trim().isEmpty) {
            return 'Condo name is required';
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildResidentFields() {
    return [
      _FieldLabel("BH Code"),
      InputField(
        hint: "Enter the BH code",
        controller: _condoCodeController,
        validator: (value) {
          if (_selectedRole == 'resident' && (value ?? '').trim().isEmpty) {
            return 'BH code is required';
          }
          return null;
        },
      ),
      const SizedBox(height: 18),
      _FieldLabel("Resident Code"),
      InputField(
        hint: "Enter your resident code",
        controller: _residentCodeController,
        validator: (value) {
          if (_selectedRole == 'resident' && (value ?? '').trim().isEmpty) {
            return 'Resident code is required';
          }
          return null;
        },
      ),
    ];
  }

  PendingSignupCredentials? get _pendingCredentials =>
      PendingSignupStore.credentials;
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
