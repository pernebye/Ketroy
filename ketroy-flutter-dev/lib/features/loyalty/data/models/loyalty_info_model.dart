import 'package:ketroy_app/features/loyalty/data/models/loyalty_level_model.dart';
import 'package:ketroy_app/features/loyalty/domain/entities/loyalty_info_entity.dart';

/// Модель полной информации о лояльности пользователя
class LoyaltyInfoModel extends LoyaltyInfoEntity {
  const LoyaltyInfoModel({
    super.currentLevel,
    super.nextLevel,
    required super.purchaseSum,
    required super.progressPercent,
    required super.amountToNext,
    required super.allLevels,
  });

  factory LoyaltyInfoModel.fromJson(Map<String, dynamic> json) {
    // current_level всегда isAchieved = true (это текущий уровень пользователя)
    // next_level всегда isAchieved = false (это следующий недостигнутый уровень)
    return LoyaltyInfoModel(
      currentLevel: json['current_level'] != null
          ? LoyaltyLevelModel.fromJson({
              ...json['current_level'] as Map<String, dynamic>,
              'is_achieved': true,
            })
          : null,
      nextLevel: json['next_level'] != null
          ? LoyaltyLevelModel.fromJson({
              ...json['next_level'] as Map<String, dynamic>,
              'is_achieved': false,
            })
          : null,
      purchaseSum: json['purchase_sum'] as int? ?? 0,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
      amountToNext: json['amount_to_next'] as int? ?? 0,
      allLevels: json['all_levels'] != null
          ? (json['all_levels'] as List)
              .map((l) => LoyaltyLevelModel.fromJson(l))
              .toList()
          : [],
    );
  }
}

/// Модель непросмотренного достижения уровня
class UnviewedLevelAchievementModel extends UnviewedLevelAchievementEntity {
  const UnviewedLevelAchievementModel({
    required super.id,
    required super.levelId,
    required super.levelName,
    required super.levelIcon,
    required super.levelColor,
    required super.achievedAt,
    required super.rewards,
  });

  factory UnviewedLevelAchievementModel.fromJson(Map<String, dynamic> json) {
    return UnviewedLevelAchievementModel(
      id: json['id'] as int,
      levelId: json['level_id'] as int,
      levelName: json['level_name'] as String? ?? '',
      levelIcon: json['level_icon'] as String? ?? '🏆',
      levelColor: json['level_color'] as String? ?? '#FFD700',
      achievedAt: DateTime.parse(json['achieved_at'] as String),
      rewards: json['rewards'] != null
          ? (json['rewards'] as List)
              .map((r) => LoyaltyRewardModel.fromJson(r))
              .toList()
          : [],
    );
  }
}

/// Ответ API для непросмотренных уровней
class UnviewedLevelsResponse {
  final bool hasNewLevels;
  final List<UnviewedLevelAchievementModel> newLevels;

  const UnviewedLevelsResponse({
    required this.hasNewLevels,
    required this.newLevels,
  });

  factory UnviewedLevelsResponse.fromJson(Map<String, dynamic> json) {
    return UnviewedLevelsResponse(
      hasNewLevels: json['has_new_levels'] as bool? ?? false,
      newLevels: json['new_levels'] != null
          ? (json['new_levels'] as List)
              .map((l) => UnviewedLevelAchievementModel.fromJson(l))
              .toList()
          : [],
    );
  }
}
