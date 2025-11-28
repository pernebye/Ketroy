import 'package:ketroy_app/features/profile/domain/entities/city_entity.dart';

class CityModel extends CityEntity {
  CityModel({required super.name, required super.phone});

  factory CityModel.fromjson(Map<String, dynamic> json) => CityModel(
        name: json['name'] ?? '',
        phone: json['city'] ?? '',
      );
}
