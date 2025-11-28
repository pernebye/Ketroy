import 'package:dio/dio.dart';

class DioExceptionService implements Exception {
  late String errorMessage;

  DioExceptionService.fromDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.cancel:
        errorMessage = "Request to the server was cancelled.";
        break;
      case DioExceptionType.connectionTimeout:
        errorMessage = "Connection timed out.";
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = "Receiving timeout occurred.";
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = "Request send timeout.";
        break;
      case DioExceptionType.badResponse:
        errorMessage = _handleStatusCode(
            dioError.response?.statusCode, dioError.response?.data['message']);
        break;
      case DioExceptionType.unknown:
        if (dioError.message!.contains('SocketException')) {
          errorMessage = 'No Internet.';
          break;
        }
        errorMessage = 'Unexpected error occurred.';
        break;
      default:
        errorMessage = 'Something went wrong';
        break;
    }
  }
  String _handleStatusCode(int? statusCode, String? message) {
    switch (statusCode) {
      case 400:
        return message ?? 'Неверный запрос';
      case 401:
        return 'Ошибка авторизации';
      case 403:
        return message ?? 'Доступ запрещён';
      case 404:
        return 'Ресурс не найден';
      case 409:
        return message ?? 'Пользователь уже существует';
      case 422:
        return message ?? 'Ошибка валидации данных';
      case 500:
        return 'Ошибка сервера';
      default:
        return message ?? 'Произошла ошибка';
    }
  }

  @override
  String toString() => errorMessage;
}
