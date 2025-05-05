import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: AppColors.textColor,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textColor,
  );

  static const TextStyle linkStyle = TextStyle(
    fontSize: 14,
    color: AppColors.primaryColor,
    fontWeight: FontWeight.w500,
  );

  // Theme Data
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundColor,
    primaryColor: AppColors.primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryColor,
      secondary: AppColors.primaryColor,
      surface: AppColors.cardColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: headingStyle,
      bodyLarge: bodyStyle,
      labelLarge: buttonTextStyle,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 1),
      ),
      hintStyle: const TextStyle(color: AppColors.secondaryTextColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryColor;
        }
        return Colors.transparent;
      }),
      side: const BorderSide(color: AppColors.primaryColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );
}
