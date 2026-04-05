// lib/config/theme_config.dart
import 'package:flutter/material.dart';

class ThemeConfig {
  // Option A: Dark Emergency Theme Colors
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceLight = Color(0xFF21262D);
  
  static const Color sosRed = Color(0xFFFF3B30);
  static const Color sosRedDark = Color(0xFFBB2B22);
  static const Color infoCyan = Color(0xFF00D4FF);
  
  static const Color safeGreen = Color(0xFF34C759);
  static const Color warningOrange = Color(0xFFFF9F0A);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8B949E);

  // Legacy compat aliases (to prevent immediate build breaks in other files)
  static const Color primaryColor = sosRed;
  static const Color dangerColor = sosRed;
  static const Color safeColor = safeGreen;
  static const Color warningColor = warningOrange;
  static const Color backgroundColor = darkBackground;

  // Gradients
  static const LinearGradient sosGradient = LinearGradient(
    colors: [sosRed, sosRedDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF21262D), Color(0xFF161B22)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Default Dark Theme Setup
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: sosRed,
    scaffoldBackgroundColor: darkBackground,
    fontFamily: 'Roboto', // Change to standard sans-serif
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 1.2,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: sosRed,
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: sosRed.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: infoCyan,
        side: const BorderSide(color: infoCyan, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      labelStyle: const TextStyle(color: textSecondary),
      prefixIconColor: infoCyan,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: infoCyan, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: sosRed, width: 1.5),
      ),
    ),
  );

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'critical':
      case 'khẩn cấp':
      case 'cao':
        return sosRed;
      case 'responding':
      case 'warning':
      case 'trung bình':
        return warningOrange;
      case 'resolved':
      case 'safe':
      case 'an toàn':
        return safeGreen;
      default:
        return textSecondary;
    }
  }
}
