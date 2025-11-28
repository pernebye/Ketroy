class BannersListEntity {
  final int id;
  final String name;
  final dynamic description;
  final List<String> cities;
  final String type;
  final String filePath;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? expiredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sortOrder;

  BannersListEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.cities,
    required this.type,
    required this.filePath,
    required this.isActive,
    this.startDate,
    this.expiredAt,
    required this.createdAt,
    required this.updatedAt,
    this.sortOrder = 0,
  });

  /// Проверяет, отображается ли баннер сейчас (учитывая start_date и expired_at)
  bool get isVisibleNow {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (expiredAt != null && now.isAfter(expiredAt!)) return false;
    return isActive;
  }

  /// Проверяет, подходит ли баннер для указанного города
  bool isVisibleForCity(String? city) {
    if (city == null || cities.contains('Все')) return true;
    return cities.contains(city);
  }
}
