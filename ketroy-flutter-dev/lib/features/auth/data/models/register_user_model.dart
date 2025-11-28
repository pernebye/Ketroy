import 'package:ketroy_app/features/auth/domain/entities/register_user_entity.dart';
import 'package:ketroy_app/core/utils/date_parser.dart';

class RegisterUserModel extends RegisterUserEntity {
  RegisterUserModel({
    required super.id,
    required super.name,
    required super.surname,
    required super.phone,
    required super.countryCode,
    required super.city,
    required super.birthdate,
    required super.height,
    required super.clothingSize,
    required super.shoeSize,
    required super.createdAt,
    required super.updatedAt,
    required super.deviceToken,
    required super.discount,
    required super.usedPromoCode,
    required super.bonusAmount,
  });

  factory RegisterUserModel.fromjson(Map<String, dynamic> json) {
    return RegisterUserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      phone: json['phone'] ?? '',
      countryCode: json['country_code'] ?? '',
      city: json['city'] ?? '',
      birthdate: json['birthdate'] ?? '',
      height: json['height'] ?? '',
      clothingSize: json['clothing_size'] ?? '',
      shoeSize: json['shoe_size'] ?? '',
      createdAt: SafeDateParser.tryParse(json['created_at']),
      updatedAt: SafeDateParser.tryParse(json['updated_at']),
      deviceToken: json['device_token'],
      discount: json['discount'],
      usedPromoCode: json['used_promo_code'] ?? false,
      bonusAmount: json['bonus_amount'],
    );
  }
}
