import 'package:flutter/material.dart';

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
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            
            // Standardizing the borders
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF5DA9E9)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        );
}