import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App Typography using Geist font family with Inter fallback.
///
/// Designed around clarity, readability, and structural hierarchy
/// rather than loud decorative weights or bright colors.
abstract final class AppTypography {
  static const String primaryFontFamily = 'Geist';
  static const String fallbackFontFamily = 'Inter';

  /// Helper to get Geist (or fallback Inter) text style
  static TextStyle _font({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    double letterSpacing = 0.0,
    Color? color,
  }) {
    try {
      return GoogleFonts.getFont(
        'Geist',
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
    } catch (_) {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
    }
  }

  // Display & Title Styles
  static TextStyle displayLarge(Color color) => _font(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.8,
        color: color,
      );

  static TextStyle displayMedium(Color color) => _font(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.6,
        color: color,
      );

  static TextStyle titleLarge(Color color) => _font(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.4,
        color: color,
      );

  static TextStyle titleMedium(Color color) => _font(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle titleSmall(Color color) => _font(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: -0.1,
        color: color,
      );

  // Body Styles
  static TextStyle bodyLarge(Color color) => _font(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: -0.1,
        color: color,
      );

  static TextStyle bodyMedium(Color color) => _font(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.0,
        color: color,
      );

  static TextStyle bodySmall(Color color) => _font(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: 0.0,
        color: color,
      );

  // Label & Microcopy Styles
  static TextStyle labelLarge(Color color) => _font(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle labelMedium(Color color) => _font(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.2,
        color: color,
      );

  static TextStyle labelSmall(Color color) => _font(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.25,
        letterSpacing: 0.3,
        color: color,
      );

  // Code / Monospace Style
  static TextStyle code(Color color, {double fontSize = 12}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: color,
    );
  }

  /// Builds a complete TextTheme for Material ThemeData
  static TextTheme textTheme(Color primaryText, Color secondaryText, Color mutedText) {
    return TextTheme(
      displayLarge: displayLarge(primaryText),
      displayMedium: displayMedium(primaryText),
      displaySmall: titleLarge(primaryText),
      headlineMedium: titleLarge(primaryText),
      headlineSmall: titleMedium(primaryText),
      titleLarge: titleLarge(primaryText),
      titleMedium: titleMedium(primaryText),
      titleSmall: titleSmall(secondaryText),
      bodyLarge: bodyLarge(primaryText),
      bodyMedium: bodyMedium(secondaryText),
      bodySmall: bodySmall(mutedText),
      labelLarge: labelLarge(primaryText),
      labelMedium: labelMedium(secondaryText),
      labelSmall: labelSmall(mutedText),
    );
  }
}
