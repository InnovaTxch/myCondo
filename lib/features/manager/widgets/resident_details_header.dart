import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';

class ResidentDetailsHeader extends StatelessWidget {
  const ResidentDetailsHeader({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.darkText,
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Resident Info',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Urbanist',
                  color: AppColors.darkText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

