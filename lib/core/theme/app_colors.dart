import 'package:flutter/material.dart';

/// Slate Color Tokens for the "Obsidian Slate" design system.
///
/// Dark Theme: Deep graphite & obsidian tones designed to eliminate glare
/// and reduce cognitive load.
/// Light Theme: Warm paper tones, carefully tuned to avoid harsh white glare.
abstract final class AppColors {
  // Dark Theme Palette (Obsidian Slate)
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF171A21);
  static const Color darkSecondarySurface = Color(0xFF20242C);
  static const Color darkBorder = Color(0xFF2B313C);
  static const Color darkPrimaryText = Color(0xFFF5F5F5);
  static const Color darkSecondaryText = Color(0xFFA1A8B3);
  static const Color darkMutedText = Color(0xFF6B7280);
  static const Color darkDivider = Color(0xFF323845);

  // Light Theme Palette (Warm Paper)
  static const Color lightBackground = Color(0xFFF7F5F0);
  static const Color lightSurface = Color(0xFFEEEAE1);
  static const Color lightSecondarySurface = Color(0xFFE2DDD2);
  static const Color lightBorder = Color(0xFFD1CBBD);
  static const Color lightPrimaryText = Color(0xFF15181E);
  static const Color lightSecondaryText = Color(0xFF525866);
  static const Color lightMutedText = Color(0xFF7D8491);
  static const Color lightDivider = Color(0xFFDDD8CB);

  // Status & Priority Colors (Muted, non-screaming tones)
  static const Color priorityUrgent = Color(0xFFE05252);
  static const Color priorityHigh = Color(0xFFE5943B);
  static const Color priorityMedium = Color(0xFF4C8DDC);
  static const Color priorityLow = Color(0xFF6B7280);

  // Semantic Status
  static const Color success = Color(0xFF2E9A60);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);
}
