class ScanEntity {
  final int discount;
  final String message;
  final String token;
  final int expiresIn;

  ScanEntity(
      {required this.discount,
      required this.message,
      required this.token,
      required this.expiresIn});
}
