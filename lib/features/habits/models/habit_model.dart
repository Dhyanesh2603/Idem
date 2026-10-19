import 'package:intl/intl.dart';

class HabitModel {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String timeOfDay; // 'morning', 'afternoon', 'evening'
  final int streakCount;
  final List<String> completedDates; // 'yyyy-MM-dd'

  const HabitModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.timeOfDay,
    this.streakCount = 0,
    this.completedDates = const [],
  });

  bool get isCompletedToday {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return completedDates.contains(todayStr);
  }

  HabitModel copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    String? timeOfDay,
    int? streakCount,
    List<String>? completedDates,
  }) {
    return HabitModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      streakCount: streakCount ?? this.streakCount,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon_name': iconName,
      'time_of_day': timeOfDay,
      'streak_count': streakCount,
      'completed_dates': completedDates,
    };
  }

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      iconName: (json['icon_name'] as String?) ?? 'check',
      timeOfDay: (json['time_of_day'] as String?) ?? 'morning',
      streakCount: (json['streak_count'] as int?) ?? 0,
      completedDates: (json['completed_dates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
