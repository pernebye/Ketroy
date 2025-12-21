import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/loyalty/data/models/loyalty_info_model.dart';
import 'package:ketroy_app/features/loyalty/domain/entities/loyalty_info_entity.dart';

/// Интерфейс репозитория лояльности
abstract interface class LoyaltyRepository {
  /// Получить полную информацию о лояльности пользователя
  Future<Either<Failure, LoyaltyInfoEntity>> getLoyaltyInfo();

  /// Получить непросмотренные достижения уровней
  Future<Either<Failure, UnviewedLevelsResponse>> getUnviewedAchievements();

  /// Отметить достижения как просмотренные
  Future<Either<Failure, int>> markLevelsViewed();
}
