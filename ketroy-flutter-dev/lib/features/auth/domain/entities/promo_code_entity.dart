class PromoCodeEntity {
  final int? id;
  final String code;
  final int? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PromoCodeEntity(
      {required this.id,
      required this.code,
      required this.userId,
      required this.createdAt,
      required this.updatedAt});
}
