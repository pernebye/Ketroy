import 'package:ketroy_app/features/news/domain/entities/banners_list_entity.dart';
import 'package:ketroy_app/core/utils/date_parser.dart';

class BannersListModel extends BannersListEntity {
  BannersListModel({
    required super.id,
    required super.name,
    required super.description,
    required super.cities,
    required super.type,
    required super.filePath,
    required super.isActive,
    super.startDate,
    super.expiredAt,
    required super.createdAt,
    required super.updatedAt,
    super.sortOrder,
  });

  factory BannersListModel.fromjson(Map<String, dynamic> map) {
    return BannersListModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      description: map['description'],
      cities: _parseCities(map['cities']),
      type: map['type'] ?? 'image',
      filePath: map['file_path'] ?? '',
      isActive: _parseIsActive(map['is_active']),
      startDate: SafeDateParser.tryParse(map['start_date']),
      expiredAt: SafeDateParser.tryParse(map['expired_at']),
      createdAt: SafeDateParser.parse(map['created_at']),
      updatedAt: SafeDateParser.parse(map['updated_at']),
      sortOrder: map['sort_order'] ?? 0,
    );
  }

  /// Парсит cities в List<String>
  static List<String> _parseCities(dynamic value) {
    if (value == null) return ['Все'];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      return [value];
    }
    return ['Все'];
  }

  /// Конвертирует is_active в bool (поддержка bool и int)
  static bool _parseIsActive(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }
}
