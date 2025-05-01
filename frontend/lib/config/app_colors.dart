import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color accentColor = Color(0xFF64B5F6);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textColor = Colors.white;
  static const Color secondaryTextColor = Colors.grey;

  // Status Colors
  static const Color statusTodo = Colors.orange;
  static const Color statusInProgress = Colors.blue;
  static const Color statusDone = Colors.green;

  // Error and Success Colors
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;

  // Main colors
  static const Color secondaryCardColor = Color(
    0xFF35383F,
  ); // Slightly lighter card color

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
