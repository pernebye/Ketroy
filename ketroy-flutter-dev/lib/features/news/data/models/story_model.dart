import 'package:ketroy_app/features/news/domain/entities/story_entity.dart';
import 'package:ketroy_app/core/utils/date_parser.dart';

class StoryModel extends StoryEntity {
  StoryModel(
      {required super.id,
      required super.name,
      required super.description,
      required super.cities,
      required super.actualGroup,
      required super.type,
      required super.filePath,
      required super.isActive,
      required super.expiredAt,
      required super.createdAt,
      required super.updatedAt,
      required super.coverPath,
      super.sortOrder = 0});

  factory StoryModel.fromJson(Map<String, dynamic> json) => StoryModel(
      id: json["id"] ?? 0,
      name: json["name"] ?? '',
      description: json["description"] ?? '',
      cities: _parseCities(json["cities"]),
      actualGroup: json["actual_group"] ?? '',
      type: json["type"] ?? '',
      filePath: json["file_path"] ?? '',
      isActive: _parseIsActive(json["is_active"]),
      expiredAt: json["expired_at"],
      createdAt: SafeDateParser.parse(json["created_at"]),
      updatedAt: SafeDateParser.parse(json["updated_at"]),
      coverPath: json['cover_path'],
      sortOrder: json['sort_order'] ?? 0);

  /// Парсит cities из JSON (поддержка array и string)
  static List<String> _parseCities(dynamic value) {
    if (value == null) return ['Все'];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return ['Все'];
  }

  /// Конвертирует is_active в int (поддержка bool и int)
  static int _parseIsActive(dynamic value) {
    if (value == null) return 0;
    if (value is bool) return value ? 1 : 0;
    if (value is int) return value;
    return 0;
  }
}
