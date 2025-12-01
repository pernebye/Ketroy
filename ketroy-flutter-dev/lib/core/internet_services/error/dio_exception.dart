import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioExceptionService implements Exception {
  late String errorMessage;

  DioExceptionService.fromDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.cancel:
        errorMessage = "Запрос был отменён";
        break;
      case DioExceptionType.connectionTimeout:
        errorMessage = "Превышено время ожидания подключения";
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = "Превышено время ожидания ответа";
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = "Превышено время отправки запроса";
        break;
      case DioExceptionType.badResponse:
        errorMessage = _handleBadResponse(dioError.response);
        break;
      case DioExceptionType.connectionError:
        errorMessage = "Ошибка подключения к серверу";
        break;
      case DioExceptionType.badCertificate:
        errorMessage = "Ошибка сертификата безопасности";
        break;
      case DioExceptionType.unknown:
        errorMessage = _handleUnknownError(dioError);
        break;
    }
    
    // Логируем ошибку для отладки
    debugPrint('🔴 DioException: $errorMessage');
    debugPrint('   Type: ${dioError.type}');
    debugPrint('   Message: ${dioError.message}');
    if (dioError.response != null) {
      debugPrint('   Status: ${dioError.response?.statusCode}');
      debugPrint('   Data: ${dioError.response?.data}');
    }
  }

  String _handleUnknownError(DioException dioError) {
    final message = dioError.message ?? '';
    final errorString = dioError.error?.toString() ?? '';
    
    if (message.contains('SocketException') || errorString.contains('SocketException')) {
      return 'Нет подключения к интернету';
    }
    if (message.contains('HandshakeException') || errorString.contains('HandshakeException')) {
      return 'Ошибка безопасного соединения';
    }
    if (message.contains('FormatException') || errorString.contains('FormatException')) {
      return 'Ошибка формата данных от сервера';
    }
    
    return 'Неизвестная ошибка сети';
  }

  String _handleBadResponse(Response? response) {
    if (response == null) {
      return 'Пустой ответ от сервера';
    }
    
    final statusCode = response.statusCode;
    final serverMessage = _extractServerMessage(response.data);
    
    return _handleStatusCode(statusCode, serverMessage);
  }

  /// Безопасно извлекает сообщение об ошибке из ответа сервера
  String? _extractServerMessage(dynamic data) {
    if (data == null) return null;
    
    // Если data - это строка, возвращаем её (иногда сервер возвращает просто текст)
    if (data is String) {
      return data.isNotEmpty ? data : null;
    }
    
    // Если data - это Map, пробуем извлечь message
    if (data is Map<String, dynamic>) {
      // Пробуем разные ключи, которые могут содержать сообщение об ошибке
      final possibleKeys = ['message', 'error', 'msg', 'detail', 'errors'];
      for (final key in possibleKeys) {
        final value = data[key];
        if (value != null) {
          if (value is String && value.isNotEmpty) {
            return value;
          }
          if (value is List && value.isNotEmpty) {
            // Если это массив ошибок, берём первую
            return value.first.toString();
          }
          if (value is Map && value.containsKey('message')) {
            return value['message']?.toString();
          }
        }
      }
    }
    
    return null;
  }

  String _handleStatusCode(int? statusCode, String? message) {
    switch (statusCode) {
      case 400:
        return message ?? 'Неверный запрос';
      case 401:
        return message ?? 'Ошибка авторизации. Войдите в аккаунт заново.';
      case 403:
        return message ?? 'Доступ запрещён';
      case 404:
        return message ?? 'Ресурс не найден';
      case 409:
        return message ?? 'Пользователь уже существует';
      case 422:
        return message ?? 'Ошибка валидации данных';
      case 429:
        return message ?? 'Слишком много запросов. Попробуйте позже.';
      case 500:
        return message ?? 'Внутренняя ошибка сервера';
      case 502:
        return message ?? 'Сервер временно недоступен';
      case 503:
        return message ?? 'Сервис временно недоступен';
      case 504:
        return message ?? 'Превышено время ожидания шлюза';
      default:
        return message ?? 'Ошибка сервера (код: $statusCode)';
    }
  }

  @override
  String toString() => errorMessage;
}
