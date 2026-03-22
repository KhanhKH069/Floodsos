//lib/config/theme_config.dart
import 'package:flutter/material.dart';

class ThemeConfig {
  // ─── Calm Crisis Palette ─────────────────────────────────────────────────
  static const Color oceanDeep   = Color(0xFF0D1B2A); // scaffold bg
  static const Color oceanMid    = Color(0xFF1B4332); // gradient end
  static const Color oceanSurface = Color(0xFF0F2D40); // card bg backing
  static const Color teal        = Color(0xFF00BCD4); // primary accent
  static const Color tealLight   = Color(0xFF4DD0E1); // light teal
  static const Color tealDark    = Color(0xFF0097A7); // pressed state
  static const Color glassWhite  = Color(0x1AFFFFFF); // glass fill (10% white)
  static const Color glassBorder = Color(0x33FFFFFF); // glass border (20% white)
  static const Color sosRed      = Color(0xFFEF5350); // SOS button label
  static const Color warnAmber   = Color(0xFFFFCA28); // warning badges

  // Calm Crisis gradients
  static const LinearGradient oceanGradient = LinearGradient(
    colors: [oceanDeep, oceanMid],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient tealGradient = LinearGradient(
    colors: [teal, tealDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Legacy / Tailwind ───────────────────────────────────────────────────
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);

  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);

  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green500 = Color(0xFF10B981);
  static const Color green600 = Color(0xFF059669);

  static const Color yellow50 = Color(0xFFFEF3C7);
  static const Color yellow100 = Color(0xFFFEF08A);
  static const Color yellow500 = Color(0xFFFBBF24);
  static const Color yellow600 = Color(0xFFD97706);

  static const Color purple50 = Color(0xFFFAF5FF);
  static const Color purple100 = Color(0xFFF3E8FF);

  // Legacy colors
  static const Color primaryColor = blue600;
  static const Color primaryDark = blue700;
  static const Color dangerColor = red500;
  static const Color dangerDark = red600;
  static const Color warningColor = yellow500;
  static const Color safeColor = green500;
  static const Color backgroundColor = gray100;
  static const Color cardColor = Colors.white;
  static const Color textPrimary = gray900;
  static const Color textSecondary = gray500;

  // Gradients
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [red600, red500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [blue700, blue500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: gray200),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.all(14),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: gray900,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: gray800,
      foregroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: gray800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: gray700),
      ),
    ),
  );

  // Common shadow for cards
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  // Status colors helper
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return red500;
      case 'responding':
        return yellow500;
      case 'resolved':
        return green500;
      default:
        return gray500;
    }
  }

  static Color getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return red50;
      case 'responding':
        return yellow50;
      case 'resolved':
        return green50;
      default:
        return gray50;
    }
  }
}
