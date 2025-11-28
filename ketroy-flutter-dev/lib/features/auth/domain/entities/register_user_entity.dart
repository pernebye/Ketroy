class RegisterUserEntity {
  final int id;
  final String name;
  final String surname;
  final String phone;
  final String countryCode;
  final String city;
  final String? birthdate;
  final String height;
  final dynamic clothingSize;
  final String shoeSize;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? deviceToken;
  final int? discount;
  final bool usedPromoCode;
  final int? bonusAmount;

  RegisterUserEntity({
    required this.id,
    required this.name,
    required this.surname,
    required this.phone,
    required this.countryCode,
    required this.city,
    required this.birthdate,
    required this.height,
    required this.clothingSize,
    required this.shoeSize,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceToken,
    required this.discount,
    required this.usedPromoCode,
    required this.bonusAmount,
  });
}
