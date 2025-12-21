import 'package:equatable/equatable.dart';

/// Entity уровня лояльности
class LoyaltyLevelEntity extends Equatable {
  final int id;
  final String name;
  final String? icon;
  final String? color;
  final int minPurchaseAmount;
  final bool isAchieved;
  final List<LoyaltyRewardEntity>? rewards;

  const LoyaltyLevelEntity({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    required this.minPurchaseAmount,
    required this.isAchieved,
    this.rewards,
  });

  @override
  List<Object?> get props => [id, name, icon, color, minPurchaseAmount, isAchieved, rewards];
}

/// Entity награды за уровень
class LoyaltyRewardEntity extends Equatable {
  final int? id;
  final String rewardType; // 'discount', 'bonus', 'gift_choice'
  final int? discountPercent;
  final int? bonusAmount;
  final String? description;

  const LoyaltyRewardEntity({
    this.id,
    required this.rewardType,
    this.discountPercent,
    this.bonusAmount,
    this.description,
  });

  /// Получить описание награды для отображения
  String get displayDescription {
    if (description != null && description!.isNotEmpty) {
      return description!;
    }
    switch (rewardType) {
      case 'discount':
        return 'Скидка $discountPercent%';
      case 'bonus':
        return '$bonusAmount бонусов';
      case 'gift_choice':
        return 'Подарок на выбор';
      default:
        return '';
    }
  }

  @override
  List<Object?> get props => [id, rewardType, discountPercent, bonusAmount, description];
}
