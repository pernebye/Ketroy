import 'package:dio/dio.dart';
import 'package:ketroy_app/core/internet_services/dio_client.dart';
import 'package:ketroy_app/core/internet_services/error/dio_exception.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/paths.dart';
import 'package:ketroy_app/features/notification/data/models/notification_model.dart';

abstract interface class NotificationDataSource {
  Future<List<NotificationModel>> getNotification();
  Future<String> notificationIsRead({required int id});
  Future<bool> notificationDeleteAll();
  Future<int> markAllAsRead(); // Отметить ВСЕ как прочитанные (1 запрос)
}

class NotificationDataSourceImpl implements NotificationDataSource {
  @override
  Future<List<NotificationModel>> getNotification() async {
    try {
      final response =
          await DioClient.instance.getList(notificationUrl, needToken: true);
      return response
          .map((notificationList) =>
              NotificationModel.fromjson(notificationList))
          .toList();
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<String> notificationIsRead({required int id}) async {
    try {
      final response = await DioClient.instance
          .post('$notificationUrl/$id/read', tokenNeed: true);
      return response['message'];
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<bool> notificationDeleteAll() async {
    try {
      await DioClient.instance
          .post('$notificationUrl/delete-all', tokenNeed: true);
      return true;
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<int> markAllAsRead() async {
    try {
      final response = await DioClient.instance
          .post('$notificationUrl/read-all', tokenNeed: true);
      return response['count'] ?? 0;
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }
}
