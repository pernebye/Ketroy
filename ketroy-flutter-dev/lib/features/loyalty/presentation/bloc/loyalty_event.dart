part of 'loyalty_bloc.dart';

/// Базовый класс событий лояльности
abstract class LoyaltyEvent {
  const LoyaltyEvent();
}

/// Загрузить информацию о лояльности
class LoadLoyaltyInfo extends LoyaltyEvent {
  const LoadLoyaltyInfo();
}

/// Проверить непросмотренные достижения
class CheckUnviewedAchievements extends LoyaltyEvent {
  const CheckUnviewedAchievements();
}

/// Отметить достижения как просмотренные
class MarkAchievementsViewed extends LoyaltyEvent {
  const MarkAchievementsViewed();
}

/// Показать модальное окно повышения уровня
class ShowLevelUpModal extends LoyaltyEvent {
  const ShowLevelUpModal();
}

/// Скрыть модальное окно повышения уровня
class DismissLevelUpModal extends LoyaltyEvent {
  const DismissLevelUpModal();
}
