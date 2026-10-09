import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Steel Orange & Deep Charcoal
  static const Color primaryOrange = Color(0xFFFF8C00); // Electric Orange
  static const Color primaryDark = Color(0xFF1A1A1A); // Deep Charcoal
  static const Color primaryLight = Color(0xFFF5F5F5); // Light Gray

  // Accent Colors
  static const Color accentYellow = Color(0xFFFFD700); // Electric Yellow
  static const Color accentBlue = Color(0xFF0066FF); // Vibrant Blue

  // Status Colors
  static const Color successGreen = Color(0xFF10B981); // Success Green
  static const Color warningRed = Color(0xFFEF4444); // Warning Red
  static const Color infoBlue = Color(0xFF3B82F6); // Info Blue

  // Grade Indicators
  static const Color gradeAColor = Color(0xFF059669); // Grade A - Green
  static const Color gradeBColor = Color(0xFFF59E0B); // Grade B - Amber

  // Background & Surface
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color darkSurface = Color(0xFF1F1F1F);
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFFF9FAFB);
  static const Color textHint = Color(0xFF9CA3AF);

  // Border Colors
  static const Color borderDark = Color(0xFF374151);
  static const Color borderLight = Color(0xFFE5E7EB);

  // Gradient
  static const List<Color> premiumGradient = [
    Color(0xFFFF8C00),
    Color(0xFFFFD700),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF1A1A1A),
    Color(0xFF2D2D2D),
  ];
}

class AppColorsTheme {
  // Light Theme
  static ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primaryOrange,
    onPrimary: Colors.white,
    secondary: AppColors.accentYellow,
    onSecondary: Colors.black,
    error: AppColors.warningRed,
    onError: Colors.white,
    surface: AppColors.lightSurface,
    onSurface: AppColors.textDark,
  );
}
