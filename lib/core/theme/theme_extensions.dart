import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_motion.dart';

/// Extension methods for quick, clean access to Obsidian Slate design tokens.
extension ThemeContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // Obsidian Slate Palette Access
  Color get background => isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
  Color get surface => isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
  Color get secondarySurface => isDarkMode ? AppColors.darkSecondarySurface : AppColors.lightSecondarySurface;
  Color get border => isDarkMode ? AppColors.darkBorder : AppColors.lightBorder;
  Color get primaryText => isDarkMode ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
  Color get secondaryText => isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
  Color get mutedText => isDarkMode ? AppColors.darkMutedText : AppColors.lightMutedText;
  Color get divider => isDarkMode ? AppColors.darkDivider : AppColors.lightDivider;

  // Active Accent
  Color get accent => colorScheme.primary;
  Color get accentSubtle => colorScheme.secondary;

  // Motion helpers
  Duration get fastDuration => AppMotion.fast;
  Duration get standardDuration => AppMotion.standard;
  Duration get moderateDuration => AppMotion.moderate;
}
