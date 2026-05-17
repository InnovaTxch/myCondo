import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';

class SubmitButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;

  const SubmitButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.primaryBlue,
        foregroundColor: AppColors.pureWhite,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.pureWhite,
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                fontFamily: "Urbanist",
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.pureWhite,
              ),
            ),
    );
  }
}
