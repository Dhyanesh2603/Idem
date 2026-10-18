import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'accent_packs.dart';
import 'app_typography.dart';

/// Builder for Obsidian Slate ThemeData.
abstract final class AppTheme {
  /// Dark Theme (Obsidian Slate)
  static ThemeData dark(AccentPack accentPack) {
    final accent = accentPack.darkPrimary;
    final accentSubtle = accentPack.darkSubtle;
    final textTheme = AppTypography.textTheme(
      AppColors.darkPrimaryText,
      AppColors.darkSecondaryText,
      AppColors.darkMutedText,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        surface: AppColors.darkSurface,
        surfaceContainerLow: AppColors.darkBackground,
        surfaceContainer: AppColors.darkSurface,
        surfaceContainerHigh: AppColors.darkSecondarySurface,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkDivider,
        primary: accent,
        onPrimary: Colors.black,
        secondary: accentSubtle,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge(AppColors.darkPrimaryText),
        iconTheme: const IconThemeData(color: AppColors.darkSecondaryText, size: 20),
        shape: const Border(
          bottom: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(
          accentPack == AccentPack.monochrome ? Colors.black : Colors.white,
        ),
        side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        hintStyle: AppTypography.bodyMedium(AppColors.darkMutedText),
        labelStyle: AppTypography.labelMedium(AppColors.darkSecondaryText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: accentPack == AccentPack.monochrome ? Colors.black : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTypography.labelLarge(Colors.white),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: AppTypography.labelMedium(accent),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimaryText,
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTypography.labelMedium(AppColors.darkPrimaryText),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: AppColors.darkSecondarySurface,
        circularTrackColor: AppColors.darkSecondarySurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkBackground,
        indicatorColor: accent.withValues(alpha: 0.15),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall(AppColors.darkPrimaryText);
          }
          return AppTypography.labelSmall(AppColors.darkMutedText);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: accent, size: 20);
          }
          return const IconThemeData(color: AppColors.darkSecondaryText, size: 20);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: accent.withValues(alpha: 0.15),
        selectedIconTheme: IconThemeData(color: accent, size: 20),
        unselectedIconTheme: const IconThemeData(color: AppColors.darkSecondaryText, size: 20),
        selectedLabelTextStyle: AppTypography.labelMedium(AppColors.darkPrimaryText),
        unselectedLabelTextStyle: AppTypography.labelMedium(AppColors.darkMutedText),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: 0.3),
        selectionHandleColor: accent,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkSecondarySurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.darkBorder, width: 1),
        ),
        textStyle: AppTypography.labelSmall(AppColors.darkPrimaryText),
        waitDuration: const Duration(milliseconds: 400),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
    );
  }

  /// Light Theme (Warm Paper)
  static ThemeData light(AccentPack accentPack) {
    final accent = accentPack.lightPrimary;
    final accentSubtle = accentPack.lightSubtle;
    final textTheme = AppTypography.textTheme(
      AppColors.lightPrimaryText,
      AppColors.lightSecondaryText,
      AppColors.lightMutedText,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.light(
        surface: AppColors.lightSurface,
        surfaceContainerLow: AppColors.lightBackground,
        surfaceContainer: AppColors.lightSurface,
        surfaceContainerHigh: AppColors.lightSecondarySurface,
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightDivider,
        primary: accent,
        onPrimary: Colors.white,
        secondary: accentSubtle,
        onSecondary: Colors.black,
        error: AppColors.error,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge(AppColors.lightPrimaryText),
        iconTheme: const IconThemeData(color: AppColors.lightSecondaryText, size: 20),
        shape: const Border(
          bottom: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        hintStyle: AppTypography.bodyMedium(AppColors.lightMutedText),
        labelStyle: AppTypography.labelMedium(AppColors.lightSecondaryText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTypography.labelLarge(Colors.white),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: AppTypography.labelMedium(accent),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightPrimaryText,
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTypography.labelMedium(AppColors.lightPrimaryText),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: AppColors.lightSecondarySurface,
        circularTrackColor: AppColors.lightSecondarySurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightBackground,
        indicatorColor: accent.withValues(alpha: 0.12),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall(AppColors.lightPrimaryText);
          }
          return AppTypography.labelSmall(AppColors.lightMutedText);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: accent, size: 20);
          }
          return const IconThemeData(color: AppColors.lightSecondaryText, size: 20);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: accent.withValues(alpha: 0.12),
        selectedIconTheme: IconThemeData(color: accent, size: 20),
        unselectedIconTheme: const IconThemeData(color: AppColors.lightSecondaryText, size: 20),
        selectedLabelTextStyle: AppTypography.labelMedium(AppColors.lightPrimaryText),
        unselectedLabelTextStyle: AppTypography.labelMedium(AppColors.lightMutedText),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: 0.25),
        selectionHandleColor: accent,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.lightSecondarySurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.lightBorder, width: 1),
        ),
        textStyle: AppTypography.labelSmall(AppColors.lightPrimaryText),
        waitDuration: const Duration(milliseconds: 400),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
    );
  }
}
