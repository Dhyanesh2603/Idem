import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'accent_packs.dart';

/// State representation for app theme settings.
class AppThemeState {
  final ThemeMode themeMode;
  final AccentPack accentPack;

  const AppThemeState({
    required this.themeMode,
    required this.accentPack,
  });

  AppThemeState copyWith({
    ThemeMode? themeMode,
    AccentPack? accentPack,
  }) {
    return AppThemeState(
      themeMode: themeMode ?? this.themeMode,
      accentPack: accentPack ?? this.accentPack,
    );
  }
}

/// Notifier to manage and persist theme & accent settings using Riverpod 3.
class ThemeNotifier extends Notifier<AppThemeState> {
  static const String _themeModeKey = 'obsidian_theme_mode';
  static const String _accentPackKey = 'obsidian_accent_pack';

  @override
  AppThemeState build() {
    // Initial default state
    final initial = const AppThemeState(
      themeMode: ThemeMode.dark,
      accentPack: AccentPack.forest,
    );
    // Asynchronously load saved settings
    _loadPreferences();
    return initial;
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_themeModeKey);
      final accentName = prefs.getString(_accentPackKey);

      ThemeMode mode = ThemeMode.dark;
      if (modeIndex != null && modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
        mode = ThemeMode.values[modeIndex];
      }

      AccentPack accent = AccentPack.forest;
      if (accentName != null) {
        accent = AccentPack.values.firstWhere(
          (a) => a.name == accentName,
          orElse: () => AccentPack.forest,
        );
      }

      state = AppThemeState(themeMode: mode, accentPack: accent);
    } catch (_) {
      // Fallback gracefully
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, mode.index);
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final next = state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  Future<void> setAccentPack(AccentPack pack) async {
    state = state.copyWith(accentPack: pack);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accentPackKey, pack.name);
    } catch (_) {}
  }
}

/// Global provider for theme state
final themeNotifierProvider = NotifierProvider<ThemeNotifier, AppThemeState>(
  ThemeNotifier.new,
);
