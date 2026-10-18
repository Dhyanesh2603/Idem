import '../../../database/app_database.dart';

/// Pure domain representation of a Category / Project.
class CategoryModel {
  final String id;
  final String name;
  final String colorHex;
  final String iconName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String syncStatus;

  const CategoryModel({
    required this.id,
    required this.name,
    this.colorHex = '#94A3B8',
    this.iconName = 'tag',
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncStatus = 'pending',
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? iconName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? syncStatus,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  factory CategoryModel.fromEntry(CategoryEntry entry) {
    return CategoryModel(
      id: entry.id,
      name: entry.name,
      colorHex: entry.colorHex,
      iconName: entry.iconName,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      isDeleted: entry.isDeleted,
      syncStatus: entry.syncStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
      'icon_name': iconName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
      'sync_status': syncStatus,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['color_hex'] as String? ?? '#94A3B8',
      iconName: json['icon_name'] as String? ?? 'tag',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isDeleted: json['is_deleted'] as bool? ?? false,
      syncStatus: json['sync_status'] as String? ?? 'synced',
    );
  }
}
