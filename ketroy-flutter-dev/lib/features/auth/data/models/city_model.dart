import 'package:ketroy_app/features/auth/domain/entities/city_entity.dart';

class CityModel extends CityEntity {
  CityModel({required super.city});

  factory CityModel.fromjson(Map<String, dynamic> json) =>
      CityModel(city: json['name'] ?? '');
}
