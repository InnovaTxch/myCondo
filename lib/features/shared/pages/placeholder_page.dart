import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    this.title = 'Coming Soon',
    this.message = 'This page is currently under construction.',
    this.icon = Icons.construction_outlined,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBlueBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.darkText,
            fontFamily: 'Urbanist',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: AppColors.primaryBlue,
                  size: 64,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontFamily: 'Urbanist',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontFamily: 'Urbanist',
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
