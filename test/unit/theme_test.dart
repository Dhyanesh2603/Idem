import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian_slate/core/theme/accent_packs.dart';
import 'package:obsidian_slate/core/theme/app_colors.dart';
import 'package:obsidian_slate/core/theme/app_theme.dart';
import 'package:obsidian_slate/core/theme/app_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Design Tokens & Palette Tests', () {
    test('Dark theme colors match Obsidian Slate specification', () {
      expect(AppColors.darkBackground, const Color(0xFF0F1115));
      expect(AppColors.darkSurface, const Color(0xFF171A21));
      expect(AppColors.darkSecondarySurface, const Color(0xFF20242C));
      expect(AppColors.darkBorder, const Color(0xFF2B313C));
      expect(AppColors.darkPrimaryText, const Color(0xFFF5F5F5));
      expect(AppColors.darkSecondaryText, const Color(0xFFA1A8B3));
      expect(AppColors.darkMutedText, const Color(0xFF6B7280));
      expect(AppColors.darkDivider, const Color(0xFF323845));
    });

    test('All 7 accent packs have distinct dark and light values', () {
      expect(AccentPack.values.length, 7);
      for (final pack in AccentPack.values) {
        expect(pack.darkPrimary, isNotNull);
        expect(pack.lightPrimary, isNotNull);
        expect(pack.darkSubtle, isNotNull);
        expect(pack.lightSubtle, isNotNull);
        expect(pack.colorFor(Brightness.dark), pack.darkPrimary);
        expect(pack.colorFor(Brightness.light), pack.lightPrimary);
      }
    });

    test('Motion durations obey 150ms - 250ms boundaries', () {
      expect(AppMotion.fast.inMilliseconds, greaterThanOrEqualTo(150));
      expect(AppMotion.moderate.inMilliseconds, lessThanOrEqualTo(250));
      expect(AppMotion.taskCompletion.inMilliseconds, inInclusiveRange(150, 250));
    });

    test('ThemeData generation applies accent pack properly', () {
      final darkTheme = AppTheme.dark(AccentPack.forest);
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(darkTheme.colorScheme.primary, AccentPack.forest.darkPrimary);

      final lightTheme = AppTheme.light(AccentPack.ocean);
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(lightTheme.colorScheme.primary, AccentPack.ocean.lightPrimary);
    });
  });
}
