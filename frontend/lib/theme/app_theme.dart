import 'package:flutter/material.dart';

/// Centralized design tokens for the F1 telemetry dashboard.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Colours
  // ---------------------------------------------------------------------------

  /// Main scaffold / page background
  static const Color darkBg = Color(0xFF0D0D0D);

  /// Slightly lighter surface for cards
  static const Color cardBg = Color(0xFF1A1A2E);

  /// Semi-transparent card surface (for glass effect)
  static const Color surfaceGlass = Color(0xCC1A1A2E); // ~80 % opacity

  /// Subtle border for glass cards
  static const Color cardBorder = Color(0x33FFFFFF); // white at 20 %

  /// F1 red – primary accent
  static const Color accentRed = Color(0xFFE10600);

  /// Cyan – secondary accent
  static const Color accentCyan = Color(0xFF00D2FF);

  /// Muted text / labels
  static const Color textMuted = Color(0xFF8A8A8A);

  /// Primary text
  static const Color textPrimary = Color(0xFFEEEEEE);

  // ---------------------------------------------------------------------------
  // Typography helpers
  // ---------------------------------------------------------------------------

  /// Racing / digital style font for numbers and headings.
  static TextStyle orbitron({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w700,
    Color color = textPrimary,
  }) {
    return TextStyle(
      fontFamily: 'Orbitron',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Clean readable font for body text and labels.
  static TextStyle inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // ---------------------------------------------------------------------------
  // Card decoration
  // ---------------------------------------------------------------------------

  /// Standard dark glass card decoration used by all telemetry widgets.
  static BoxDecoration glassCard({double borderRadius = 16}) {
    return BoxDecoration(
      color: surfaceGlass,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: cardBorder, width: 1),
    );
  }

  // ---------------------------------------------------------------------------
  // Full app theme
  // ---------------------------------------------------------------------------

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: accentRed,
        secondary: accentCyan,
        surface: cardBg,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111122),
        elevation: 0,
      ),
    );
  }
}
