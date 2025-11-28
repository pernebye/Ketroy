import 'package:ketroy_app/features/news/domain/entities/categories_entity.dart';

class CategoriesModel extends CategoriesEntity {
  CategoriesModel({required super.name});

  factory CategoriesModel.fromJson(Map<String, dynamic> json) =>
      CategoriesModel(
        name: json["name"] ?? '',
      );
}
