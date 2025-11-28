class ShopEntity {
  final int id;
  final String name;
  final String description;
  final String city;
  final String filePath;
  final String openingHours;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String twoGisAddress;
  final String? addresses;
  final String instagram;
  final String whatsApp;

  ShopEntity(
      {required this.id,
      required this.name,
      required this.description,
      required this.city,
      required this.filePath,
      required this.openingHours,
      required this.createdAt,
      required this.updatedAt,
      required this.twoGisAddress,
      this.addresses,
      required this.instagram,
      required this.whatsApp});
}
