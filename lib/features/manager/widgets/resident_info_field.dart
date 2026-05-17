import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';

class ResidentInfoField extends StatelessWidget {
  const ResidentInfoField({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.darkText, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Urbanist',
                color: Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

