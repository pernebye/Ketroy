import 'package:ketroy_app/features/shop_detail/domain/entities/shop_entity.dart';

class ShopModel extends ShopEntity {
  ShopModel(
      {required super.id,
      required super.name,
      required super.description,
      required super.city});

  factory ShopModel.fromJson(Map<String, dynamic> json) => ShopModel(
        id: json["id"] ?? '',
        name: json["name"] ?? '',
        description: json["description"] ?? '',
        city: json["city"] ?? '',
      );
}
