/// Информация о реферальной программе
class ReferralInfo {
  final bool isAvailable;
  final String? promoCode;
  final String? shareUrl;
  
  // Флаг: уже применял ли пользователь промокод друга
  final bool hasUsedPromoCode;
  
  // Настройки для реферера (владельца промокода)
  final int referrerBonusPercent;
  final int referrerMaxPurchases;
  final int referrerHighDiscountThreshold; // Порог высокой скидки (обычно 30%)
  
  // Настройки для нового пользователя
  final int newUserDiscountPercent;
  final int newUserBonusPercent;
  final int newUserBonusPurchases;
  
  // Статистика
  final int totalReferred;
  
  // Описание (с бэкенда)
  final String? description;

  const ReferralInfo({
    required this.isAvailable,
    this.promoCode,
    this.shareUrl,
    this.hasUsedPromoCode = false,
    this.referrerBonusPercent = 2,
    this.referrerMaxPurchases = 3,
    this.referrerHighDiscountThreshold = 30,
    this.newUserDiscountPercent = 10,
    this.newUserBonusPercent = 5,
    this.newUserBonusPurchases = 1,
    this.totalReferred = 0,
    this.description,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    return ReferralInfo(
      isAvailable: json['is_available'] ?? false,
      promoCode: json['promo_code'],
      shareUrl: json['share_url'],
      hasUsedPromoCode: json['has_used_promo_code'] ?? false,
      referrerBonusPercent: json['referrer_bonus_percent'] ?? 2,
      referrerMaxPurchases: json['referrer_max_purchases'] ?? 3,
      referrerHighDiscountThreshold: json['referrer_high_discount_threshold'] ?? 30,
      newUserDiscountPercent: json['new_user_discount_percent'] ?? 10,
      newUserBonusPercent: json['new_user_bonus_percent'] ?? 5,
      newUserBonusPurchases: json['new_user_bonus_purchases'] ?? 1,
      totalReferred: json['total_referred'] ?? 0,
      description: json['description'],
    );
  }

  /// Описание для реферера (что он получит)
  String getReferrerDescription() {
    return 'Получайте $referrerBonusPercent% бонусов с первых $referrerMaxPurchases покупок друга';
  }

  /// Описание для нового пользователя (что он получит)
  String getNewUserDescription() {
    String desc = 'Получите скидку $newUserDiscountPercent%';
    if (newUserBonusPercent > 0) {
      desc += ' и $newUserBonusPercent% бонусов с первых $newUserBonusPurchases покупок';
    }
    return desc;
  }
  
  /// Полное описание для шаринга
  String getShareDescription() {
    return 'Поделитесь промокодом с другом и получайте $referrerBonusPercent% с его первых $referrerMaxPurchases покупок.';
  }
  
  /// Описание для друга
  String getFriendDescription() {
    String desc = 'Получите персональную скидку $newUserDiscountPercent%';
    if (newUserBonusPercent > 0) {
      desc += ' и $newUserBonusPercent% бонусов с первых $newUserBonusPurchases покупок';
    }
    desc += '.';
    return desc;
  }
}

