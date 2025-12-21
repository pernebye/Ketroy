part of 'loyalty_bloc.dart';

/// Статус загрузки лояльности
enum LoyaltyStatus {
  initial,
  loading,
  success,
  failure,
}

/// Состояние лояльности
class LoyaltyState {
  final LoyaltyStatus status;
  final LoyaltyInfoEntity? loyaltyInfo;
  final List<UnviewedLevelAchievementModel> unviewedAchievements;
  final bool showLevelUpModal;
  final String? errorMessage;

  const LoyaltyState({
    this.status = LoyaltyStatus.initial,
    this.loyaltyInfo,
    this.unviewedAchievements = const [],
    this.showLevelUpModal = false,
    this.errorMessage,
  });

  /// Текущий уровень пользователя
  String? get currentLevelName => loyaltyInfo?.currentLevel?.name;

  /// Иконка текущего уровня
  String? get currentLevelIcon => loyaltyInfo?.currentLevel?.icon;

  /// Цвет текущего уровня
  String? get currentLevelColor => loyaltyInfo?.currentLevel?.color;

  /// Есть ли непросмотренные достижения
  bool get hasUnviewedAchievements => unviewedAchievements.isNotEmpty;

  /// Первое непросмотренное достижение (для показа в модальном окне)
  UnviewedLevelAchievementModel? get firstUnviewedAchievement =>
      unviewedAchievements.isNotEmpty ? unviewedAchievements.first : null;

  LoyaltyState copyWith({
    LoyaltyStatus? status,
    LoyaltyInfoEntity? loyaltyInfo,
    List<UnviewedLevelAchievementModel>? unviewedAchievements,
    bool? showLevelUpModal,
    String? errorMessage,
  }) {
    return LoyaltyState(
      status: status ?? this.status,
      loyaltyInfo: loyaltyInfo ?? this.loyaltyInfo,
      unviewedAchievements: unviewedAchievements ?? this.unviewedAchievements,
      showLevelUpModal: showLevelUpModal ?? this.showLevelUpModal,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
