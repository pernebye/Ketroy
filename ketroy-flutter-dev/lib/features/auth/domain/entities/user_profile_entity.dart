class ProfileUserEntity {
  final int id;
  final String name;
  final String phone;
  final dynamic avatarImage;
  final String countryCode;
  final String city;
  final String? birthdate;
  final String? height;
  final String? clothingSize;
  final String? shoeSize;
  final String verificationCode;
  final String? codeExpiresAt;
  final String? createdAt;
  final String? updatedAt;
  final dynamic deviceToken;
  final String surname;
  final int discount;
  final int usedPromoCode;
  final String referrerId;
  final int bonusAmount;

  ProfileUserEntity(
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
      required this.codeExpiresAt,
      required this.createdAt,
      required this.updatedAt,
      required this.deviceToken,
      required this.surname,
      required this.discount,
      required this.usedPromoCode,
      required this.referrerId,
      required this.bonusAmount});
}
