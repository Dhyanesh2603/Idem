import 'package:intl/intl.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/repository/task_repository.dart';

class ScheduledSlot {
  final TaskModel task;
  final DateTime startTime;
  final DateTime endTime;

  const ScheduledSlot({
    required this.task,
    required this.startTime,
    required this.endTime,
  });

  String get timeFormatted {
    final startStr = DateFormat('h:mm a').format(startTime);
    final endStr = DateFormat('h:mm a').format(endTime);
    return '$startStr – $endStr';
  }
}

class SmartSchedulePlan {
  final List<ScheduledSlot> slots;
  final int totalMinutes;
  final String cognitiveLoadLevel; // 'Low', 'Optimal', 'High'
  final String message;

  const SmartSchedulePlan({
    required this.slots,
    required this.totalMinutes,
    required this.cognitiveLoadLevel,
    required this.message,
  });
}

class SmartDayScheduler {
  static SmartSchedulePlan generatePlan({
    required List<TaskModel> tasks,
    DateTime? dayStart,
  }) {
    final pendingTasks = tasks.where((t) => !t.isCompleted && !t.isDeleted).toList();

    // Sort by priority (urgent -> high -> medium -> low) and duration
    pendingTasks.sort((a, b) {
      final pComp = a.priority.index.compareTo(b.priority.index);
      if (pComp != 0) return pComp;
      return b.estimatedMinutes.compareTo(a.estimatedMinutes);
    });

    final now = DateTime.now();
    var currentCursor = dayStart ??
        DateTime(now.year, now.month, now.day, 9, 0); // Default 9:00 AM

    // If current time is already later than 9am today, snap to next 15-minute mark
    if (dayStart == null && now.isAfter(currentCursor)) {
      final minute = ((now.minute / 15).ceil() * 15).toInt();
      currentCursor = DateTime(now.year, now.month, now.day, now.hour, 0).add(Duration(minutes: minute));
    }

    final slots = <ScheduledSlot>[];
    int totalMinutes = 0;

    for (final task in pendingTasks) {
      final duration = task.estimatedMinutes > 0 ? task.estimatedMinutes : 45;

      // Check if crossing lunch time (12:30 PM - 1:15 PM)
      final lunchStart = DateTime(currentCursor.year, currentCursor.month, currentCursor.day, 12, 30);
      final lunchEnd = DateTime(currentCursor.year, currentCursor.month, currentCursor.day, 13, 15);

      if (currentCursor.isBefore(lunchStart) && currentCursor.add(Duration(minutes: duration)).isAfter(lunchStart)) {
        // Postpone task to after lunch
        currentCursor = lunchEnd;
      }

      final start = currentCursor;
      final end = start.add(Duration(minutes: duration));

      slots.add(ScheduledSlot(
        task: task,
        startTime: start,
        endTime: end,
      ));

      totalMinutes += duration;
      // 10-minute cognitive buffer between tasks
      currentCursor = end.add(const Duration(minutes: 10));
    }

    String loadLevel;
    String message;
    if (totalMinutes <= 180) {
      loadLevel = 'Light';
      message = 'Light focus load. Ideal for creative incubation and exploratory coding.';
    } else if (totalMinutes <= 360) {
      loadLevel = 'Optimal';
      message = 'Optimal high-performance flow. Balanced between deep work and execution.';
    } else {
      loadLevel = 'Heavy';
      message = 'Intense cognitive load. Ensure adequate hydration and micro-breaks.';
    }

    return SmartSchedulePlan(
      slots: slots,
      totalMinutes: totalMinutes,
      cognitiveLoadLevel: loadLevel,
      message: message,
    );
  }

  static Future<int> applyPlanToRepository({
    required SmartSchedulePlan plan,
    required TaskRepository repo,
  }) async {
    int updatedCount = 0;
    for (final slot in plan.slots) {
      final updated = slot.task.copyWith(
        deadline: slot.endTime,
      );
      await repo.updateTask(updated);
      updatedCount++;
    }
    return updatedCount;
  }
}
