import 'package:flutter/material.dart';

class AppColors {
  static const skyBlue = Color(0xFF8EC5F8);
  static const softLavender = Color(0xFFE8D9FF);
  static const pureWhite = Color(0xFFFFFFFF);
  static const lightBlueBackground = Color(0xFFF4FAFF);
  static const creamWhite = Color(0xFFF7F5F2);
  static const primaryBlue = Color(0xFF4A90FF);
  static const successGreen = Color(0xFF34A853);
  static const warningGold = Color(0xFFF4C96B);
  static const warningOrange = Color(0xFFE0A11B);
  static const errorRed = Color(0xFFD32F2F);
  static const softGray = Color(0xFFE5E5E5);
  static const darkText = Color(0xFF1A1A1A);
  static const secondaryText = Color(0xFF7A7A7A);
  static const black = Color(0xFF111111);
}

class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryBlue,
      onPrimary: AppColors.pureWhite,
      secondary: AppColors.softLavender,
      onSecondary: AppColors.darkText,
      tertiary: AppColors.skyBlue,
      onTertiary: AppColors.darkText,
      error: AppColors.errorRed,
      onError: AppColors.pureWhite,
      surface: AppColors.pureWhite,
      onSurface: AppColors.darkText,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBlueBackground,
      fontFamily: 'Urbanist',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pureWhite,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.pureWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.softGray),
        ),
      ),
      dividerColor: AppColors.softGray,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryBlue,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkText,
        contentTextStyle: const TextStyle(
          color: AppColors.pureWhite,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.pureWhite,
          disabledBackgroundColor: AppColors.softGray,
          disabledForegroundColor: AppColors.secondaryText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkText,
          side: const BorderSide(color: AppColors.softGray),
          backgroundColor: AppColors.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.creamWhite,
        indicatorColor: AppColors.black,
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(
            color: AppColors.secondaryText,
            size: 22,
          ),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryText,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.creamWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.softGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.softGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.darkText),
        headlineMedium: TextStyle(color: AppColors.darkText),
        headlineSmall: TextStyle(color: AppColors.darkText),
        titleLarge: TextStyle(color: AppColors.darkText),
        titleMedium: TextStyle(color: AppColors.darkText),
        titleSmall: TextStyle(color: AppColors.darkText),
        bodyLarge: TextStyle(color: AppColors.darkText),
        bodyMedium: TextStyle(color: AppColors.darkText),
        bodySmall: TextStyle(color: AppColors.secondaryText),
        labelLarge: TextStyle(color: AppColors.darkText),
        labelMedium: TextStyle(color: AppColors.secondaryText),
        labelSmall: TextStyle(color: AppColors.secondaryText),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppStatusColors(
          success: AppColors.successGreen,
          warning: AppColors.warningGold,
          warningStrong: AppColors.warningOrange,
          destructive: AppColors.errorRed,
          activeNav: AppColors.black,
        ),
      ],
    );
  }
}

@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.warning,
    required this.warningStrong,
    required this.destructive,
    required this.activeNav,
  });

  final Color success;
  final Color warning;
  final Color warningStrong;
  final Color destructive;
  final Color activeNav;

  @override
  AppStatusColors copyWith({
    Color? success,
    Color? warning,
    Color? warningStrong,
    Color? destructive,
    Color? activeNav,
  }) {
    return AppStatusColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      warningStrong: warningStrong ?? this.warningStrong,
      destructive: destructive ?? this.destructive,
      activeNav: activeNav ?? this.activeNav,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) {
      return this;
    }
    return AppStatusColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningStrong: Color.lerp(warningStrong, other.warningStrong, t) ?? warningStrong,
      destructive: Color.lerp(destructive, other.destructive, t) ?? destructive,
      activeNav: Color.lerp(activeNav, other.activeNav, t) ?? activeNav,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppStatusColors get appStatusColors =>
      Theme.of(this).extension<AppStatusColors>() ??
      const AppStatusColors(
        success: AppColors.successGreen,
        warning: AppColors.warningGold,
        warningStrong: AppColors.warningOrange,
        destructive: AppColors.errorRed,
        activeNav: AppColors.black,
      );
}
