import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';

class InputField extends StatefulWidget {
  const InputField({
    super.key,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.validator,
  });

  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final String? Function(String?)? validator;

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  late bool _hidden;

  @override
  void initState() {
    super.initState();
    _hidden = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      validator: widget.validator,
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: true,
        fillColor: const Color(0xFFDEEAF5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        // Eye icon — only shown on password fields
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.secondaryText,
                  size: 20,
                ),
                onPressed: () => setState(() => _hidden = !_hidden),
                splashRadius: 20,
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:
              const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
      ),
    );
  }
}