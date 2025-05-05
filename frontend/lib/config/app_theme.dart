import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.backgroundColor,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryColor,
      secondary: AppColors.accentColor,
      surface: AppColors.cardColor,
      background: AppColors.backgroundColor,
    ),
    cardColor: AppColors.cardColor,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textColor),
      bodyMedium: TextStyle(color: AppColors.textColor),
      titleLarge: TextStyle(color: AppColors.textColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardColor,
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
        borderSide: const BorderSide(color: AppColors.primaryColor),
      ),
      labelStyle: const TextStyle(color: AppColors.secondaryTextColor),
      prefixIconColor: AppColors.secondaryTextColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
      ),
    ),
  );
}
