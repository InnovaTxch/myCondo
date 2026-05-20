import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';

class InputField extends TextFormField {
  InputField({
    super.key,
    required String hint,
    required TextEditingController super.controller,
    super.obscureText,
    super.validator,
  }) : super(
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFDEEAF5), // soft blue-grey, darker than lightBlueBackground
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
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