import 'package:equatable/equatable.dart';
import 'package:ketroy_app/features/loyalty/domain/entities/loyalty_level_entity.dart';

/// Entity полной информации о лояльности пользователя
class LoyaltyInfoEntity extends Equatable {
  final LoyaltyLevelEntity? currentLevel;
  final LoyaltyLevelEntity? nextLevel;
  final int purchaseSum;
  final double progressPercent;
  final int amountToNext;
  final List<LoyaltyLevelEntity> allLevels;

  const LoyaltyInfoEntity({
    this.currentLevel,
    this.nextLevel,
    required this.purchaseSum,
    required this.progressPercent,
    required this.amountToNext,
    required this.allLevels,
  });

  /// Проверить, есть ли текущий уровень
  bool get hasCurrentLevel => currentLevel != null;

  /// Проверить, достигнут ли максимальный уровень
  bool get isMaxLevel => nextLevel == null && currentLevel != null;

  /// Форматированная сумма покупок
  String get formattedPurchaseSum => _formatAmount(purchaseSum);

  /// Форматированная сумма до следующего уровня
  String get formattedAmountToNext => _formatAmount(amountToNext);

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} млн ₸';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} тыс ₸';
    }
    return '$amount ₸';
  }

  @override
  List<Object?> get props => [
        currentLevel,
        nextLevel,
        purchaseSum,
        progressPercent,
        amountToNext,
        allLevels,
      ];
}

/// Entity непросмотренного достижения уровня
class UnviewedLevelAchievementEntity extends Equatable {
  final int id;
  final int levelId;
  final String levelName;
  final String levelIcon;
  final String levelColor;
  final DateTime achievedAt;
  final List<LoyaltyRewardEntity> rewards;

  const UnviewedLevelAchievementEntity({
    required this.id,
    required this.levelId,
    required this.levelName,
    required this.levelIcon,
    required this.levelColor,
    required this.achievedAt,
    required this.rewards,
  });

  @override
  List<Object?> get props => [
        id,
        levelId,
        levelName,
        levelIcon,
        levelColor,
        achievedAt,
        rewards,
      ];
}
