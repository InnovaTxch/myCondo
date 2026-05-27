import 'package:flutter/material.dart';
import 'package:mycondo/data/repositories/auth/auth_service.dart';
import 'package:mycondo/features/auth/widgets/signup_form.dart';
import 'package:mycondo/features/auth/widgets/login_gateway.dart';
import 'package:mycondo/features/shared/widgets/submit_button.dart';
import 'package:mycondo/services/shared/session_preference_service.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/utils/app_snackbar.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();
  final SessionPreferenceService _sessionPreferenceService =
      SessionPreferenceService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> signUp() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);
    try {
      final response = await _authService.signUpWithEmailPassword(
        email,
        password,
      );
      final hasSession =
          response.session != null ||
          _authService.getCurrentUserEmail() != null;

      if (!mounted) return;

      if (!hasSession) {
        context.showAppMessage(
          'Account created. Please sign in to continue. If your project requires email confirmation, check your inbox first.',
        );
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _sessionPreferenceService.retainSessionForOnboarding();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding');
    } catch (e) {
      if (!mounted) return;
      context.showAppError(
        e,
        fallbackMessage: 'Could not create your account. Please try again.',
        debugLabel: 'SignupScreen.signUp',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Column(
        children: [
          // ── Top: full-bleed image with blue overlay ──────────────────
          Expanded(
            flex: 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/images/house.png', fit: BoxFit.cover),

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryBlue.withValues(alpha: 0.55),
                        AppColors.primaryBlue.withValues(alpha: 0.80),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  left: 28,
                  bottom: 36,
                  right: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Create an\naccount.",
                        style: TextStyle(
                          fontFamily: "Urbanist",
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pureWhite,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Managers set up a condo. \nResidents join with condo and resident codes.",
                        style: TextStyle(
                          fontFamily: "Urbanist",
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom: form card ─────────────────────────────────────────
          Expanded(
            flex: 7,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.lightBlueBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SignupForm(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                    ),

                    const SizedBox(height: 28),

                    SubmitButton(
                      text: "Sign up",
                      onPressed: _isLoading ? null : signUp,
                      isLoading: _isLoading,
                      color: AppColors.primaryBlue,
                    ),

                    const SizedBox(height: 24),

                    LoginGateway(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
