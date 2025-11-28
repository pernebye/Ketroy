import 'package:ketroy_app/features/auth/domain/entities/country_codes_entity.dart';

class CountryCodesModel extends CountryCodesEntity {
  CountryCodesModel({required super.country, required super.code});

  factory CountryCodesModel.fromjson(Map<String, dynamic> json) =>
      CountryCodesModel(country: json['country'], code: json['code']);
}
