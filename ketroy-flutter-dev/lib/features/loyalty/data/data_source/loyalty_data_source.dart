import 'package:dio/dio.dart';
import 'package:ketroy_app/core/internet_services/dio_client.dart';
import 'package:ketroy_app/core/internet_services/error/dio_exception.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/features/loyalty/data/models/loyalty_info_model.dart';

/// Endpoints для API лояльности
const String _loyaltyInfoUrl = '/user/loyalty';
const String _loyaltyUnviewedUrl = '/user/loyalty/unviewed';
const String _loyaltyMarkViewedUrl = '/user/loyalty/mark-viewed';

/// Интерфейс источника данных для лояльности
abstract interface class LoyaltyDataSource {
  /// Получить полную информацию о лояльности пользователя
  Future<LoyaltyInfoModel> getLoyaltyInfo();

  /// Получить непросмотренные достижения уровней
  Future<UnviewedLevelsResponse> getUnviewedAchievements();

  /// Отметить достижения как просмотренные
  Future<int> markLevelsViewed();
}

/// Реализация источника данных для лояльности
class LoyaltyDataSourceImpl implements LoyaltyDataSource {
  @override
  Future<LoyaltyInfoModel> getLoyaltyInfo() async {
    try {
      final response = await DioClient.instance.get(
        _loyaltyInfoUrl,
        needToken: true,
      );
      return LoyaltyInfoModel.fromJson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<UnviewedLevelsResponse> getUnviewedAchievements() async {
    try {
      final response = await DioClient.instance.get(
        _loyaltyUnviewedUrl,
        needToken: true,
      );
      return UnviewedLevelsResponse.fromJson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<int> markLevelsViewed() async {
    try {
      final response = await DioClient.instance.post(
        _loyaltyMarkViewedUrl,
        tokenNeed: true,
      );
      return response['marked_count'] as int? ?? 0;
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }
}
