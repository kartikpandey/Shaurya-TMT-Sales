import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Display Styles (Large headlines)
  static TextStyle displayLarge(BuildContext context) {
    return GoogleFonts.interTight(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    );
  }

  static TextStyle displayMedium(BuildContext context) {
    return GoogleFonts.interTight(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.3,
    );
  }

  // Headline Styles
  static TextStyle headlineLarge(BuildContext context) {
    return GoogleFonts.interTight(fontSize: 24, fontWeight: FontWeight.w700);
  }

  static TextStyle headlineMedium(BuildContext context) {
    return GoogleFonts.interTight(fontSize: 20, fontWeight: FontWeight.w700);
  }

  static TextStyle headlineSmall(BuildContext context) {
    return GoogleFonts.interTight(fontSize: 18, fontWeight: FontWeight.w700);
  }

  // Title Styles
  static TextStyle titleLarge(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );
  }

  static TextStyle titleMedium(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
  }

  static TextStyle titleSmall(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    );
  }

  // Body Styles
  static TextStyle bodyLarge(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    );
  }

  static TextStyle bodyMedium(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
    );
  }

  static TextStyle bodySmall(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.5,
    );
  }

  // Label Styles
  static TextStyle labelLarge(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    );
  }

  static TextStyle labelMedium(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    );
  }

  static TextStyle labelSmall(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    );
  }

  // Numeric Styles (for coins, units, etc.)
  static TextStyle numericLarge(BuildContext context) {
    return GoogleFonts.interTight(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
    );
  }

  static TextStyle numericMedium(BuildContext context) {
    return GoogleFonts.interTight(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    );
  }

  static TextStyle numericSmall(BuildContext context) {
    return GoogleFonts.interTight(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    );
  }

  // Button Styles
  static TextStyle buttonLarge(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
  }

  static TextStyle buttonMedium(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );
  }

  static TextStyle buttonSmall(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
  }
}
