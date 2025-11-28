import 'package:ketroy_app/features/shop/domain/entities/shop_entity.dart';
import 'package:ketroy_app/core/utils/date_parser.dart';

class ShopModel extends ShopEntity {
  ShopModel({
    required super.id,
    required super.name,
    required super.description,
    required super.city,
    required super.filePath,
    required super.openingHours,
    required super.createdAt,
    required super.updatedAt,
    required super.twoGisAddress,
    super.addresses,
    required super.instagram,
    required super.whatsApp,
  });
  factory ShopModel.fromjson(Map<String, dynamic> json) => ShopModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      city: json['city'] ?? '',
      filePath: json['file_path'] ?? '',
      openingHours: json['opening_hours'] ?? '',
      createdAt: SafeDateParser.parse(json['created_at']),
      updatedAt: SafeDateParser.parse(json['updated_at']),
      twoGisAddress: json['two_gis_address'] ?? '',
      addresses: json['address'],
      instagram: json['instagram'] ?? '',
      whatsApp: json['whatsapp'] ?? '');
}
