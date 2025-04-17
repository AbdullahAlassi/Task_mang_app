import 'package:flutter/material.dart';

class AppColors {
  // Main colors
  static const Color primaryColor = Color(0xFF246BFD); // Blue accent color
  static const Color backgroundColor = Color(0xFF181A20); // Dark background
  static const Color cardColor = Color(0xFF1F222A); // Card/input background
  static const Color secondaryCardColor = Color(
    0xFF35383F,
  ); // Slightly lighter card color

  // Text colors
  static const Color textColor = Colors.white;
  static const Color secondaryTextColor = Color(0xFF9E9E9E); // Gray text

  // UI element colors
  static const Color dividerColor = Color(0xFF35383F);
  static const Color checkboxBorderColor = Color(0xFF246BFD);

  // Project colors
  static const Color projectPurple = Color(
    0xFF65558F,
  ); // Purple for project cards
  static const Color projectGreen = Color(
    0xFF4CAF50,
  ); // Green for completed tasks
  static const Color projectRed = Color(0xFFF44336); // Red for urgent tasks
  static const Color projectYellow = Color(0xFFFFEB3B); // Yellow for warnings

  // Status colors
  static const Color statusTodo = Color(0xFF757575); // Gray for to-do
  static const Color statusInProgress = Color(
    0xFF246BFD,
  ); // Blue for in progress
  static const Color statusDone = Color(0xFF4CAF50); // Green for done

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF246BFD), Color(0xFF3677FD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Opacity variants
  static Color primaryWithOpacity(double opacity) =>
      primaryColor.withOpacity(opacity);
  static Color backgroundWithOpacity(double opacity) =>
      backgroundColor.withOpacity(opacity);
}
