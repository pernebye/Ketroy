/// Модель акции (Promotion)
/// Типы акций:
/// - single_purchase: единовременная покупка
/// - friend_discount: подари скидку другу
/// - date_based: по дате
/// - birthday: день рождения
/// - lottery: лотерея
class PromotionModel {
  final int id;
  final String name;
  final String type;
  final String? description;
  final Map<String, dynamic>? settings;
  final String? startDate;
  final String? endDate;
  final bool isArchived;
  final bool isActive;
  final String? modalTitle;
  final String? modalText;
  final String? modalImage;
  final String? modalButtonText;
  final List<PromotionGiftModel> gifts;

  PromotionModel({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.settings,
    this.startDate,
    this.endDate,
    this.isArchived = false,
    this.isActive = true,
    this.modalTitle,
    this.modalText,
    this.modalImage,
    this.modalButtonText,
    this.gifts = const [],
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: _parseToInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString(),
      settings: json['settings'] is Map ? Map<String, dynamic>.from(json['settings']) : null,
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      isArchived: json['is_archived'] == true || json['is_archived'] == 1,
      isActive: json['is_active'] != false && json['is_active'] != 0,
      modalTitle: json['modal_title']?.toString(),
      modalText: json['modal_text']?.toString(),
      modalImage: json['modal_image']?.toString(),
      modalButtonText: json['modal_button_text']?.toString(),
      gifts: json['gifts'] != null
          ? List<PromotionGiftModel>.from(
              json['gifts'].map((x) => PromotionGiftModel.fromJson(x)))
          : [],
    );
  }

  /// Получить отображаемое название типа акции
  String get typeDisplayName {
    switch (type) {
      case 'single_purchase':
        return 'Единовременная покупка';
      case 'friend_discount':
        return 'Подари скидку другу';
      case 'date_based':
        return 'Акция по дате';
      case 'birthday':
        return 'День рождения';
      case 'lottery':
        return 'Лотерея';
      default:
        return 'Акция';
    }
  }

  /// Получить иконку для типа акции
  String get typeIcon {
    switch (type) {
      case 'single_purchase':
        return '🛍️';
      case 'friend_discount':
        return '🤝';
      case 'date_based':
        return '📅';
      case 'birthday':
        return '🎂';
      case 'lottery':
        return '🎰';
      default:
        return '🎁';
    }
  }

  /// Проверка активности акции
  bool get isCurrentlyActive {
    if (!isActive || isArchived) return false;
    
    final now = DateTime.now();
    
    if (startDate != null) {
      final start = DateTime.tryParse(startDate!);
      if (start != null && now.isBefore(start)) return false;
    }
    
    if (endDate != null) {
      final end = DateTime.tryParse(endDate!);
      if (end != null && now.isAfter(end.add(const Duration(days: 1)))) return false;
    }
    
    return true;
  }

  /// Получить настройки в зависимости от типа (безопасное преобразование)
  int? get minPurchaseAmount => _parseToInt(settings?['min_purchase_amount']);
  int? get discountPercent => _parseToInt(settings?['discount_percent']);
  int? get durationDays => _parseToInt(settings?['duration_days']);
  int? get daysBefore => _parseToInt(settings?['days_before']);

  /// Безопасное преобразование значения в int
  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }
}

/// Модель подарка акции
class PromotionGiftModel {
  final int id;
  final int promotionId;
  final int? giftCatalogId;
  final GiftCatalogModel? giftCatalog;

  PromotionGiftModel({
    required this.id,
    required this.promotionId,
    this.giftCatalogId,
    this.giftCatalog,
  });

  factory PromotionGiftModel.fromJson(Map<String, dynamic> json) {
    return PromotionGiftModel(
      id: _parseToInt(json['id']) ?? 0,
      promotionId: _parseToInt(json['promotion_id']) ?? 0,
      giftCatalogId: _parseToInt(json['gift_catalog_id']),
      giftCatalog: json['gift_catalog'] != null
          ? GiftCatalogModel.fromJson(json['gift_catalog'])
          : null,
    );
  }

  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }
}

/// Модель подарка из каталога
class GiftCatalogModel {
  final int id;
  final String name;
  final String? image;
  final bool isActive;

  GiftCatalogModel({
    required this.id,
    required this.name,
    this.image,
    this.isActive = true,
  });

  factory GiftCatalogModel.fromJson(Map<String, dynamic> json) {
    return GiftCatalogModel(
      id: _parseToInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
      isActive: json['is_active'] != false && json['is_active'] != 0,
    );
  }

  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }
}

