import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';

class InputField extends TextFormField {
  InputField({
    super.key,
    required String hint,
    required TextEditingController super.controller,
    super.obscureText,
    super.validator
  }) : super(
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.pureWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            
            // Standardizing the borders
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: AppColors.primaryBlue),
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
