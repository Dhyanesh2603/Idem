import 'package:flutter/animation.dart';

/// Motion and timing tokens for Obsidian Slate.
///
/// Motion philosophy:
/// - Duration 150ms to 250ms strictly
/// - Never attract attention to the animation itself
/// - Communicates state changes clearly and calmly
/// - Standard cubic/quad easing
/// - No bounce, no playful spring physics, no spinning loaders
abstract final class AppMotion {
  // Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration moderate = Duration(milliseconds: 250);

  // Curves
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve decelerate = Curves.decelerate;

  // Specific Action Durations
  static const Duration taskCompletion = Duration(milliseconds: 220);
  static const Duration checkboxCheck = Duration(milliseconds: 180);
  static const Duration modalTransition = Duration(milliseconds: 200);
  static const Duration pageTransition = Duration(milliseconds: 220);
  static const Duration filterChange = Duration(milliseconds: 160);
  static const Duration hover = Duration(milliseconds: 140);
}
