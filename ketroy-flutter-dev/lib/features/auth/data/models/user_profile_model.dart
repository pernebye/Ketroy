import 'package:ketroy_app/features/auth/domain/entities/user_profile_entity.dart';

class ProfileUserModel extends ProfileUserEntity {
  ProfileUserModel(
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
      required super.codeExpiresAt,
      required super.createdAt,
      required super.updatedAt,
      required super.deviceToken,
      required super.surname,
      required super.discount,
      required super.usedPromoCode,
      required super.referrerId,
      required super.bonusAmount});

  factory ProfileUserModel.fromjson(Map<String, dynamic> json) =>
      ProfileUserModel(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        avatarImage: json['avatar_image'],
        countryCode: json['country_code'] ?? '',
        city: json['city'] ?? '',
        birthdate: json['birthdate'],
        height: json['height'],
        clothingSize: json['clothing_size'],
        shoeSize: json['shoe_size'],
        verificationCode: json['verification_code'] ?? '',
        codeExpiresAt: json['code_expires_at'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
        deviceToken: json['device_token'],
        surname: json['surname'] ?? '',
        discount: json['discount'] ?? 0,
        usedPromoCode: json['used_promo_code'] ?? 0,
        referrerId: json['referrer_id'] ?? '',
        bonusAmount: json['bonus_amount'] ?? 0,
      );
}
