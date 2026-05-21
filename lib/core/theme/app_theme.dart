import 'package:flutter/material.dart';

class AppTheme {
  // Brand Palette
  static const Color primaryTeal = Color(0xFF0D9488); // Teal-600
  static const Color primaryLightTeal = Color(0xFFCCFBF1); // Teal-100
  static const Color secondaryBlue = Color(0xFF1E3A8A); // Blue-900
  static const Color accentCyan = Color(0xFF06B6D4); // Cyan-500
  static const Color background = Color(0xFFF8FAFC); // Slate-50
  static const Color white = Colors.white;
  
  // Severity Levels
  static const Color severityLow = Color(0xFF059669); // Green-600
  static const Color severityMedium = Color(0xFFD97706); // Amber-600
  static const Color severityEmergency = Color(0xFFDC2626); // Red-600

  // Shading Colors
  static const Color borderLight = Color(0xFFE2E8F0); // Slate-200
  static const Color textDark = Color(0xFF0F172A); // Slate-900
  static const Color textMuted = Color(0xFF64748B); // Slate-500

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryTeal,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: secondaryBlue,
        tertiary: accentCyan,
        background: background,
        surface: white,
        error: severityEmergency,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: secondaryBlue, size: 24),
        titleTextStyle: TextStyle(
          color: secondaryBlue,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.04),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: primaryTeal, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: severityEmergency, width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: secondaryBlue, fontWeight: FontWeight.bold, fontSize: 32),
        headlineMedium: TextStyle(color: secondaryBlue, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: TextStyle(color: secondaryBlue, fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: textDark, fontSize: 16, height: 1.4),
        bodyMedium: TextStyle(color: textMuted, fontSize: 14, height: 1.4),
      ),
    );
  }

  // Get color depending on severity string
  static Color getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'emergency':
      case 'high':
        return severityEmergency;
      case 'medium':
      case 'moderate':
        return severityMedium;
      case 'low':
      default:
        return severityLow;
    }
  }
}
