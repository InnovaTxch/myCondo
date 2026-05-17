import 'package:flutter/material.dart';
import 'package:mycondo/data/repositories/auth/pending_signup_credentials.dart';

import 'package:mycondo/features/auth/widgets/signup_form.dart';
import 'package:mycondo/features/auth/widgets/login_gateway.dart';
import 'package:mycondo/features/shared/widgets/submit_button.dart';
import 'package:mycondo/theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>{
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // SIGNUP BUTTON PRESSED
  Future <void> signUp() async {
    final isValid = _formKey.currentState!.validate();
    if(!isValid) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    PendingSignupStore.save(email: email, password: password);

    if(!mounted) return;
    Navigator.pushReplacementNamed(context, '/onboarding');

  }

  @override
  void dispose(){
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: ListView(
          children: [
            // Top Gap
            const SizedBox(height: 60),

            Text(
              "Create an\naccount.",
              style: TextStyle(
                fontFamily: "Urbanist",
                fontSize: 45,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Managers can set up a condo. Residents can join with condo and resident codes.",
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 15,
                height: 1.35,
              ),
            ),

            const SizedBox(height: 30),

            SignupForm(
              formKey: _formKey, 
              emailController: _emailController, 
              passwordController: _passwordController, 
              confirmPasswordController: _confirmPasswordController
            ),

            const SizedBox(height: 20),

            SubmitButton(
              text: "Sign up", 
              onPressed: _isLoading ? null : signUp, 
              isLoading: _isLoading, 
              color: AppColors.primaryBlue
            ),

            const SizedBox(height: 20),

            LoginGateway()
          ],
        ),
      ),
    );
  }
}
