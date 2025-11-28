import 'package:ketroy_app/features/news/data/models/blocks_list_model.dart';
import 'package:ketroy_app/features/news/domain/entities/news_list_entity.dart';
import 'package:ketroy_app/core/utils/date_parser.dart';

class NewsListModel extends NewsListEntity {
  NewsListModel(
      {required super.id,
      required super.isActive,
      required super.name,
      required super.cities,
      required super.categories,
      required super.height,
      required super.clothingSize,
      required super.shoeSize,
      required super.expiredAt,
      required super.createdAt,
      required super.updatedAt,
      required super.publishedAt,
      required super.blocks,
      super.sortOrder = 0});

  factory NewsListModel.fromJson(Map<String, dynamic> json) => NewsListModel(
      id: json["id"] ?? 0,
      isActive: _parseIsActive(json["is_active"]),
      name: json["name"] ?? '',
      cities: _parseStringList(json["city"]),
      categories: _parseStringList(json["category"]),
      height: json["height"],
      clothingSize: json["clothing_size"],
      shoeSize: json["shoe_size"],
      expiredAt: SafeDateParser.tryParse(json["expired_at"]),
      createdAt: SafeDateParser.parse(json["created_at"]),
      updatedAt: SafeDateParser.parse(json["updated_at"]),
      publishedAt: SafeDateParser.parse(json["published_at"]),
      blocks: List<BlocksListModel>.from(
          (json['blocks'] ?? []).map((x) => BlocksListModel.fromjson(x))),
      sortOrder: json["sort_order"] ?? 0);

  /// Парсит строку или массив в List<String>
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return [];
  }

  /// Конвертирует is_active в int (поддержка bool и int)
  static int _parseIsActive(dynamic value) {
    if (value == null) return 0;
    if (value is bool) return value ? 1 : 0;
    if (value is int) return value;
    return 0;
  }
}
