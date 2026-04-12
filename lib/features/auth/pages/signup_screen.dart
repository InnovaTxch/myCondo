import 'package:flutter/material.dart';
import 'package:mycondo/data/repositories/auth/auth_service.dart';

import 'package:mycondo/features/auth/widgets/signup_form.dart';
import 'package:mycondo/features/auth/widgets/login_gateway.dart';
import 'package:mycondo/features/shared/widgets/submit_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>{
  // get auth service
  final authService = AuthService();

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

    setState(() => _isLoading = true);

    try {
      await authService.signUpWithEmailPassword(email, password);
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Signup successful!")));

    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error signup up: $e")));

    } finally {
      if(!mounted) return;
      setState(() => _isLoading = false);
    }

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
      backgroundColor: Color(0xFFF4F4F4),
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
              color: Color(0xFF5DA9E9)
            ),

            const SizedBox(height: 20),

            LoginGateway()
          ],
        ),
      ),
    );
  }
}
