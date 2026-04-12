import 'package:flutter/material.dart';
import 'dart:io';

import 'package:mycondo/data/repositories/auth/auth_service.dart';

import 'package:mycondo/features/auth/widgets/login_form.dart';
import 'package:mycondo/features/shared/widgets/submit_button.dart';
import 'package:mycondo/features/auth/widgets/signup_gateway.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>{
  final authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  Future <void> signIn() async {
    final isValid = _formKey.currentState!.validate();
    if(!isValid) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
    await authService.signInWithEmailPassword(email, password);
    
    if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful!")),
      );
      
      String? role = await authService.getRole();

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context, 
        role == 'manager' ? '/manager-dashboard' : '/resident-dashboard'
      );

    } on SocketException {
      if (!mounted) return;
      _showError("No internet connection. Please check your network.");

    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
      
    } catch (e) {
      if (!mounted) return;
      _showError("An unexpected error occurred: $e");

    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose(){
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F4F4),

      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: ListView(
          children: [
            SizedBox(height: 50),
            Text(
              "Welcome\nback!",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 30),

            LoginForm(
              formKey: _formKey, 
              emailController: _emailController, 
              passwordController: _passwordController
            ),

            SizedBox(height: 20),

            SubmitButton(
              text: "Log in", 
              onPressed: _isLoading ? null : signIn,
              isLoading: _isLoading,
              color: Color(0xFF5DA9E9),
            ),

            const SizedBox(height: 20),

            SignupGateway()
          ],
        ),
      ),
    );
  }
}
