import 'package:flutter/material.dart';

import 'package:mycondo/data/repositories/auth/auth_service.dart';
import 'package:mycondo/utils/app_snackbar.dart';

import 'package:mycondo/features/auth/widgets/login_form.dart';
import 'package:mycondo/features/shared/widgets/submit_button.dart';
import 'package:mycondo/features/auth/widgets/signup_gateway.dart';
import 'package:mycondo/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _keepSignedIn = false;

  Future<void> signIn() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      await authService.signInWithEmailPassword(
        email,
        password,
        keepSignedIn: _keepSignedIn,
      );

      if (!mounted) return;
      context.showAppSnackBar(
        const SnackBar(content: Text("Login successful!")),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } catch (e) {
      if (!mounted) return;
      context.showAppError(
        e,
        fallbackMessage: 'Login failed. Please try again.',
        debugLabel: 'LoginScreen.signIn',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                Image.asset('assets/images/house.png', fit: BoxFit.cover),

                // Blue overlay
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

                // Text on image
                Positioned(
                  left: 28,
                  bottom: 36,
                  right: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Welcome\nback!",
                        style: TextStyle(
                          fontFamily: "Urbanist",
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pureWhite,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Sign in to manage your condo.",
                        style: TextStyle(
                          fontFamily: "Urbanist",
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom: white card ────────────────────────────────────────
          Expanded(
            flex: 6,
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
                    LoginForm(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      keepSignedIn: _keepSignedIn,
                      onKeepSignedInChanged: (value) {
                        setState(() => _keepSignedIn = value);
                      },
                    ),
                    const SizedBox(height: 24),

                    SubmitButton(
                      text: "Log in",
                      onPressed: _isLoading ? null : signIn,
                      isLoading: _isLoading,
                      color: AppColors.primaryBlue,
                    ),

                    const SizedBox(height: 24),

                    SignupGateway(),
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
