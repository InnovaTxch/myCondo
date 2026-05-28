import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';

class ResidentDetailsHeader extends StatelessWidget {
  const ResidentDetailsHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Text(
              '←',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
                height: 1,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Resident Info',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
