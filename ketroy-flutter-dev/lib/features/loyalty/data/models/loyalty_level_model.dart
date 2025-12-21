import 'package:ketroy_app/features/loyalty/domain/entities/loyalty_level_entity.dart';

/// Модель уровня лояльности
class LoyaltyLevelModel extends LoyaltyLevelEntity {
  const LoyaltyLevelModel({
    required super.id,
    required super.name,
    super.icon,
    super.color,
    required super.minPurchaseAmount,
    required super.isAchieved,
    super.rewards,
  });

  factory LoyaltyLevelModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyLevelModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      minPurchaseAmount: json['min_purchase_amount'] as int? ?? 0,
      isAchieved: json['is_achieved'] as bool? ?? false,
      rewards: json['rewards'] != null
          ? (json['rewards'] as List)
              .map((r) => LoyaltyRewardModel.fromJson(r))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'min_purchase_amount': minPurchaseAmount,
      'is_achieved': isAchieved,
      'rewards': rewards?.map((r) => (r as LoyaltyRewardModel).toJson()).toList(),
    };
  }
}

/// Модель награды за уровень
class LoyaltyRewardModel extends LoyaltyRewardEntity {
  const LoyaltyRewardModel({
    super.id,
    required super.rewardType,
    super.discountPercent,
    super.bonusAmount,
    super.description,
  });

  factory LoyaltyRewardModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyRewardModel(
      id: json['id'] as int?,
      rewardType: json['reward_type'] as String? ?? '',
      discountPercent: json['discount_percent'] as int?,
      bonusAmount: json['bonus_amount'] as int?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reward_type': rewardType,
      'discount_percent': discountPercent,
      'bonus_amount': bonusAmount,
      'description': description,
    };
  }
}
