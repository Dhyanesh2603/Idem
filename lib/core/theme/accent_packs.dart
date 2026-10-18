import 'package:flutter/material.dart';

/// Available Accent Color Packs.
///
/// Note: Accent packs ONLY affect:
/// - Checkboxes
/// - Selection Indicators
/// - Progress Indicators
/// - Buttons
/// - Focus States
/// - Links
/// - Navigation Indicators
///
/// Everything else remains strictly monochrome/slate.
enum AccentPack {
  forest('Forest', 'Calm pine and eucalyptus green'),
  ocean('Ocean', 'Deep nautical azure and sea foam'),
  amber('Amber', 'Warm honey and roasted spice'),
  burgundy('Burgundy', 'Subtle dark ruby and wine'),
  lavender('Lavender', 'Refined lilac and twilight purple'),
  slate('Slate', 'Understated balanced mineral gray'),
  monochrome('Monochrome', 'Pure high-contrast black and white');

  const AccentPack(this.displayName, this.description);

  final String displayName;
  final String description;

  /// Primary accent color for dark theme
  Color get darkPrimary {
    switch (this) {
      case AccentPack.forest:
        return const Color(0xFF34D399); // Crisp Emerald/Forest
      case AccentPack.ocean:
        return const Color(0xFF60A5FA); // Radiant Cobalt/Ocean
      case AccentPack.amber:
        return const Color(0xFFFBBF24); // Warm Amber
      case AccentPack.burgundy:
        return const Color(0xFFFB7185); // Rose/Burgundy
      case AccentPack.lavender:
        return const Color(0xFFA78BFA); // Soft Lavender
      case AccentPack.slate:
        return const Color(0xFF94A3B8); // Slate Zinc
      case AccentPack.monochrome:
        return const Color(0xFFF5F5F5); // Crisp Light
    }
  }

  /// Secondary/subtle accent for dark theme (hover, container tints)
  Color get darkSubtle {
    switch (this) {
      case AccentPack.forest:
        return const Color(0xFF064E3B);
      case AccentPack.ocean:
        return const Color(0xFF1E3A8A);
      case AccentPack.amber:
        return const Color(0xFF78350F);
      case AccentPack.burgundy:
        return const Color(0xFF881337);
      case AccentPack.lavender:
        return const Color(0xFF4C1D95);
      case AccentPack.slate:
        return const Color(0xFF334155);
      case AccentPack.monochrome:
        return const Color(0xFF262626);
    }
  }

  /// Primary accent color for light theme
  Color get lightPrimary {
    switch (this) {
      case AccentPack.forest:
        return const Color(0xFF059669);
      case AccentPack.ocean:
        return const Color(0xFF2563EB);
      case AccentPack.amber:
        return const Color(0xFFD97706);
      case AccentPack.burgundy:
        return const Color(0xFFBE123C);
      case AccentPack.lavender:
        return const Color(0xFF7C3AED);
      case AccentPack.slate:
        return const Color(0xFF475569);
      case AccentPack.monochrome:
        return const Color(0xFF18181B);
    }
  }

  /// Secondary/subtle accent for light theme
  Color get lightSubtle {
    switch (this) {
      case AccentPack.forest:
        return const Color(0xFFD1FAE5);
      case AccentPack.ocean:
        return const Color(0xFFDBEAFE);
      case AccentPack.amber:
        return const Color(0xFFFEF3C7);
      case AccentPack.burgundy:
        return const Color(0xFFFFE4E6);
      case AccentPack.lavender:
        return const Color(0xFFEDE9FE);
      case AccentPack.slate:
        return const Color(0xFFE2E8F0);
      case AccentPack.monochrome:
        return const Color(0xFFE4E4E7);
    }
  }

  /// Accent for the active brightness
  Color colorFor(Brightness brightness) {
    return brightness == Brightness.dark ? darkPrimary : lightPrimary;
  }

  /// Subtle tint for active brightness
  Color subtleColorFor(Brightness brightness) {
    return brightness == Brightness.dark ? darkSubtle : lightSubtle;
  }
}
