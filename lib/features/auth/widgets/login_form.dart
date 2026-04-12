import 'package:flutter/material.dart';
import '../../shared/widgets/input_field.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController
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
        ],
      ),
    );
  }
}