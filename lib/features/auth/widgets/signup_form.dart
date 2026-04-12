import 'package:flutter/material.dart';
import '../../shared/widgets/input_field.dart';

class SignupForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const SignupForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  String? emailValidator(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Please enter your email';
    }

    if (!text.contains('@') || !text.contains('.')) {
      return 'Please enter a valid email';
    }

    return null;
  }

  String? passwordValidator(String? value) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Please enter your password';
    }

    if (text.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  String? confirmPasswordValidator(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Please confirm your password';
    }

    if (value != passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        spacing: 20.0,
        children: [
          InputField(
            hint: "Email",
            controller: emailController,
            validator: emailValidator,
          ),
          InputField(
            hint: "Password",
            controller: passwordController,
            validator: passwordValidator,
            obscureText: true,
          ),
          InputField(
            hint: "Confirm Password",
            controller: confirmPasswordController,
            validator: confirmPasswordValidator,
            obscureText: true,
          ),
        ],
      ),
    );
  }
}