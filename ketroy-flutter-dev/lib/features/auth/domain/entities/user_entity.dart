import 'package:ketroy_app/features/auth/domain/entities/promo_code_entity.dart';

class AuthUserEntity {
  final int id;
  final String name;
  final String phone;
  final dynamic avatarImage;
  final String countryCode;
  final String city;
  final String? birthdate;
  final String height;
  final dynamic clothingSize;
  final String shoeSize;
  final String verificationCode;
  final DateTime? codeExpires;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? deviceToken;
  final String surname;
  final int? discount;
  final int? userPromoCode;
  final int? referrerId;
  final int? bonusAmount;
  final PromoCodeEntity? promoCode;

  AuthUserEntity(
      {required this.id,
      required this.name,
      required this.phone,
      required this.avatarImage,
      required this.countryCode,
      required this.city,
      required this.birthdate,
      required this.height,
      required this.clothingSize,
      required this.shoeSize,
      required this.verificationCode,
      required this.codeExpires,
      required this.createdAt,
      required this.updatedAt,
      required this.deviceToken,
      required this.surname,
      required this.discount,
      required this.userPromoCode,
      required this.referrerId,
      required this.bonusAmount,
      required this.promoCode});
}
