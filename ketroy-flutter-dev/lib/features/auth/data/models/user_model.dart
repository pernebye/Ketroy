import 'package:ketroy_app/features/auth/data/models/promo_code_model.dart';
import 'package:ketroy_app/features/auth/domain/entities/user_entity.dart';
import 'package:ketroy_app/core/utils/date_parser.dart';

class AuthUserModel extends AuthUserEntity {
  AuthUserModel(
      {required super.id,
      required super.name,
      required super.phone,
      required super.avatarImage,
      required super.countryCode,
      required super.city,
      required super.birthdate,
      required super.height,
      required super.clothingSize,
      required super.shoeSize,
      required super.verificationCode,
      required super.codeExpires,
      required super.createdAt,
      required super.updatedAt,
      required super.deviceToken,
      required super.surname,
      required super.discount,
      required super.userPromoCode,
      required super.referrerId,
      required super.bonusAmount,
      required super.promoCode});

  factory AuthUserModel.fromjson(Map<String, dynamic> json) => AuthUserModel(
      verificationCode: json['verification_code'] ?? '',
      codeExpires: SafeDateParser.tryParse(json['code_expires_at']),
      createdAt: SafeDateParser.tryParse(json['created_at']),
      updatedAt: SafeDateParser.tryParse(json['updated_at']),
      deviceToken: json['device_token'] ?? '',
      discount: _parseIntOrNull(json['discount']),
      userPromoCode: _parseBoolOrIntToInt(json['used_promo_code']),
      referrerId: _parseIntOrNull(json['referrer_id']),
      bonusAmount: _parseIntOrNull(json['bonus_amount']),
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      id: json['id'] ?? 0,
      avatarImage: json['avatar_image'],
      countryCode: json['country_code'] ?? '',
      city: json['city'] ?? '',
      birthdate: json['birthdate'] ?? '',
      height: json['height'] ?? '',
      clothingSize: json['clothing_size'] ?? '',
      shoeSize: json['shoe_size'] ?? '',
      surname: json['surname'] ?? '',
      promoCode: json['promo_code'] != null
          ? PromoCodeModel.fromjson(json['promo_code'])
          : null);

  /// Конвертирует bool или int в int? (для used_promo_code)
  static int? _parseBoolOrIntToInt(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value ? 1 : 0;
    if (value is int) return value;
    return null;
  }

  /// Безопасно парсит int или null
  static int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
