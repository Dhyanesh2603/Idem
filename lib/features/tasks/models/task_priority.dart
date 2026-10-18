import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Semantic task priority levels.
enum TaskPriority {
  urgent('Urgent', 4, AppColors.priorityUrgent),
  high('High', 3, AppColors.priorityHigh),
  medium('Medium', 2, AppColors.priorityMedium),
  low('Low', 1, AppColors.priorityLow),
  none('None', 0, AppColors.darkMutedText);

  const TaskPriority(this.displayName, this.weight, this.color);

  final String displayName;
  final int weight;
  final Color color;

  static TaskPriority fromString(String? value) {
    if (value == null) return TaskPriority.none;
    return TaskPriority.values.firstWhere(
      (p) => p.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TaskPriority.none,
    );
  }
}
