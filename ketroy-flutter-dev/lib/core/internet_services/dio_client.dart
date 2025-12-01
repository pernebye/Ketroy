/// ============================================
/// KETROY APP - DIO HTTP CLIENT
/// ============================================
/// Централизованный HTTP клиент с поддержкой dev/prod
library dio_client;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ketroy_app/core/config/app_config.dart';
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';
import 'dart:async';

class DioClient {
  DioClient._() {
    _initializeDio();
  }

  static final instance = DioClient._();
  
  /// Stream для оповещения о 401 ошибках авторизации
  /// Подписчики могут сбросить состояние авторизации при получении события
  static final StreamController<void> _authErrorController = 
      StreamController<void>.broadcast();
  
  /// Stream для прослушивания ошибок авторизации (401)
  static Stream<void> get onAuthError => _authErrorController.stream;

  late final Dio _dio;

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      responseType: ResponseType.json,
      followRedirects: true,
      maxRedirects: 3,
    ));

    // Retry interceptor для нестабильных соединений
    _dio.interceptors.add(RetryInterceptor(dio: _dio));

    // Interceptor для автоматического добавления токена и сохранения для редиректов
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await UserDataManager.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // Сохраняем Authorization в extra для редиректов
        if (options.headers.containsKey('Authorization')) {
          options.extra['authHeader'] = options.headers['Authorization'];
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Токен истёк - очищаем данные
          await UserDataManager.clearUserData();
          debugPrint('⚠️ Token expired, user data cleared');
          // Оповещаем о необходимости сброса состояния авторизации
          _authErrorController.add(null);
        }
        return handler.next(error);
      },
    ));

    // Логирование запросов в debug режиме
    if (AppConfig.enableLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: false, // Отключаем логирование больших ответов
        error: true,
        logPrint: (obj) => debugPrint('📡 DIO: $obj'),
      ));
    }
  }

  /// Получить базовые заголовки
  Map<String, dynamic> _getHeaders({bool needToken = true, String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (needToken && token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET запрос
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool needToken = true,
  }) async {
    final token = await UserDataManager.getToken();
    try {
      final Response response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options:
            Options(headers: _getHeaders(needToken: needToken, token: token)),
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Ошибка сервера: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET запрос (возвращает List)
  /// [listKey] - ключ для извлечения списка из Map ответа (например, 'data' или 'cities')
  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool needToken = false,
    String? listKey,
  }) async {
    final token = await UserDataManager.getToken();
    try {
      final Response response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options:
            Options(headers: _getHeaders(needToken: needToken, token: token)),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        // Если ответ уже List - возвращаем как есть
        if (data is List) {
          return data;
        }
        // Если ответ Map - извлекаем список по ключу
        if (data is Map<String, dynamic>) {
          if (listKey != null && data.containsKey(listKey)) {
            return data[listKey] as List<dynamic>;
          }
          // Автоопределение: если Map с одним ключом-списком
          final listEntries = data.entries.where((e) => e.value is List);
          if (listEntries.length == 1) {
            return listEntries.first.value as List<dynamic>;
          }
          throw DioException(
            requestOptions: response.requestOptions,
            message: 'Ответ API - Map, но listKey не указан или не найден',
          );
        }
        throw DioException(
          requestOptions: response.requestOptions,
          message: 'Неожиданный формат ответа: ${data.runtimeType}',
        );
      }
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Ошибка сервера: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// POST запрос
  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool tokenNeed = false,
  }) async {
    final token = await UserDataManager.getToken();
    try {
      final Response response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options:
            Options(headers: _getHeaders(needToken: tokenNeed, token: token)),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Ошибка сервера: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// POST запрос с FormData (для файлов)
  Future<Map<String, dynamic>> postFormData(
    String path, {
    FormData? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool tokenNeed = false,
  }) async {
    final token = await UserDataManager.getToken();
    final headers = {
      'Accept': 'application/json',
      if (tokenNeed && token != null) 'Authorization': 'Bearer $token',
      // Content-Type не указываем - Dio сам установит для FormData
    };
    try {
      final Response response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleUnauthorized();
        throw DioException(
          requestOptions: response.requestOptions,
          message: 'Токен истёк. Необходимо войти заново.',
        );
      }
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Ошибка сервера: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// PUT запрос
  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final token = await UserDataManager.getToken();
    try {
      final Response response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: _getHeaders(token: token)),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Ошибка сервера: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// PUT запрос с FormData (для файлов)
  Future<Map<String, dynamic>> putFormData(
    String path, {
    FormData? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final token = await UserDataManager.getToken();
    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    try {
      final Response response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleUnauthorized();
        throw DioException(
          requestOptions: response.requestOptions,
          message: 'Токен истёк. Необходимо войти заново.',
        );
      }
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Ошибка сервера: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE запрос
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final token = await UserDataManager.getToken();
    try {
      final Response response = await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: Options(headers: _getHeaders(token: token)),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Ошибка сервера: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Обработка истёкшего токена
  Future<void> _handleUnauthorized() async {
    await UserDataManager.clearUserData();
    debugPrint('⚠️ Unauthorized - user data cleared');
  }
}

/// Retry interceptor для автоматического повтора запросов при ошибках соединения
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.retryDelay = const Duration(seconds: 1),
  });

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    // Повторяем только при определённых ошибках
    final shouldRetry = _shouldRetry(err);
    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

    if (shouldRetry && retryCount < maxRetries) {
      debugPrint(
          '🔄 Retry ${retryCount + 1}/$maxRetries for ${err.requestOptions.uri}');

      await Future.delayed(retryDelay);

      try {
        err.requestOptions.extra['retryCount'] = retryCount + 1;
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        // Если retry тоже неудачный, передаём ошибку дальше
        if (e is DioException) {
          return handler.next(e);
        }
      }
    }

    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.type == DioExceptionType.unknown &&
            err.error.toString().contains('FormatException'));
  }
}
