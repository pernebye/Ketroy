import 'package:ketroy_app/features/news/domain/entities/blocks_list_entity.dart';

class NewsListEntity {
  final int id;
  final int isActive;
  final String name;
  final List<String> cities;
  final List<String> categories;
  final dynamic height;
  final String? clothingSize;
  final String? shoeSize;
  final DateTime? expiredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime publishedAt;
  final List<BlocksListEntity> blocks;
  final int sortOrder;

  NewsListEntity(
      {required this.id,
      required this.isActive,
      required this.name,
      required this.cities,
      required this.categories,
      required this.height,
      required this.clothingSize,
      required this.shoeSize,
      required this.expiredAt,
      required this.createdAt,
      required this.updatedAt,
      required this.publishedAt,
      required this.blocks,
      this.sortOrder = 0});
  
  /// Геттер для первого города (для обратной совместимости)
  String get city => cities.isNotEmpty ? cities.first : '';
  
  /// Геттер для первой категории (для обратной совместимости)
  String get category => categories.isNotEmpty ? categories.first : '';
}
