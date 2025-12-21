import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/loyalty/data/data_source/loyalty_data_source.dart';
import 'package:ketroy_app/features/loyalty/data/models/loyalty_info_model.dart';
import 'package:ketroy_app/features/loyalty/domain/entities/loyalty_info_entity.dart';
import 'package:ketroy_app/features/loyalty/domain/repository/loyalty_repository.dart';

/// Реализация репозитория лояльности
class LoyaltyRepositoryImpl implements LoyaltyRepository {
  final LoyaltyDataSource loyaltyDataSource;

  LoyaltyRepositoryImpl({required this.loyaltyDataSource});

  @override
  Future<Either<Failure, LoyaltyInfoEntity>> getLoyaltyInfo() async {
    try {
      final result = await loyaltyDataSource.getLoyaltyInfo();
      return Right(result);
    } on ServerException catch (e) {
      return Left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, UnviewedLevelsResponse>> getUnviewedAchievements() async {
    try {
      final result = await loyaltyDataSource.getUnviewedAchievements();
      return Right(result);
    } on ServerException catch (e) {
      return Left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, int>> markLevelsViewed() async {
    try {
      final result = await loyaltyDataSource.markLevelsViewed();
      return Right(result);
    } on ServerException catch (e) {
      return Left(Failure(e.message));
    }
  }
}
