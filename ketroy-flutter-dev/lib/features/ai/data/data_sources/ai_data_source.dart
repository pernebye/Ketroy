import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ketroy_app/core/internet_services/dio_client.dart';
import 'package:ketroy_app/core/internet_services/error/dio_exception.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/paths.dart';
import 'package:ketroy_app/features/ai/data/models/ai_model.dart';
import 'package:ketroy_app/features/ai/data/models/chat_message_model.dart';

abstract interface class AiDataSource {
  Future<AiModel> getAiResponseData({required File imageFile, String? languageCode});
  
  /// Отправить сообщение в чат с историей
  Future<String> sendChatMessage({
    required String message,
    required List<ChatMessage> chatHistory,
    File? imageFile,
    String? languageCode,
  });
}

class AiDataSourceImpl implements AiDataSource {
  @override
  Future<AiModel> getAiResponseData({
    required File imageFile,
    String? languageCode = 'en',
  }) async {
    try {
      // Определяем язык ответа (по умолчанию - русский, если не передан)
      final responseLanguage = languageCode ?? 'ru';
      
      print('[AiDataSource] Starting request with language: $responseLanguage');
      print('[AiDataSource] File path: ${imageFile.path}');
      print('[AiDataSource] File exists: ${imageFile.existsSync()}');
      print('[AiDataSource] File size: ${imageFile.lengthSync()} bytes');

      // Создаем FormData с файлом и языком
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        'language': responseLanguage, // Передаём язык на сервер
      });

      print('[AiDataSource] FormData created, sending to server...');
      
      final response = await DioClient.instance
          .postFormData(clothingAnalyze, data: formData, tokenNeed: true);
      
      print('[AiDataSource] Response received: $response');
      print('[AiDataSource] Response type: ${response.runtimeType}');
      print('[AiDataSource] Full response JSON: ${response.toString()}');
      
      final model = AiModel.fromjson(response);
      print('[AiDataSource] Parsed model - success: ${model.success}, analysis length: ${model.analysis.length}');
      print('[AiDataSource] Analysis content: ${model.analysis}');
      
      return model;
    } on DioException catch (e) {
      print('[AiDataSource] DioException: ${e.message}');
      print('[AiDataSource] Response: ${e.response?.data}');
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    } catch (e) {
      print('[AiDataSource] Unexpected error: $e');
      throw ServerException('Неожиданная ошибка: $e');
    }
  }

  @override
  Future<String> sendChatMessage({
    required String message,
    required List<ChatMessage> chatHistory,
    File? imageFile,
    String? languageCode,
  }) async {
    try {
      final responseLanguage = languageCode ?? 'ru';
      
      print('[AiDataSource] Chat request with ${chatHistory.length} history messages');
      
      // Преобразуем историю в формат API
      final historyForApi = chatHistory
          .where((msg) => !msg.isLoading)
          .map((msg) => msg.toApiFormat())
          .toList();

      // Если есть изображение - используем FormData
      if (imageFile != null) {
        print('[AiDataSource] Sending chat with IMAGE');
        print('[AiDataSource] Message: $message');
        print('[AiDataSource] Image path: ${imageFile.path}');
        print('[AiDataSource] Image exists: ${imageFile.existsSync()}');
        print('[AiDataSource] History count: ${historyForApi.length}');
        
        final formData = FormData.fromMap({
          'message': message,
          'chat_history': jsonEncode(historyForApi),
          'language': responseLanguage,
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        });

        print('[AiDataSource] FormData fields: ${formData.fields}');

        final response = await DioClient.instance
            .postFormData(clothingChat, data: formData, tokenNeed: true);
        
        print('[AiDataSource] Chat with image response: $response');
        
        return response['message'] ?? '';
      } else {
        // Только текст - используем JSON
        final response = await DioClient.instance.post(
          clothingChat,
          data: {
            'message': message,
            'chat_history': historyForApi,
            'language': responseLanguage,
          },
          tokenNeed: true,
        );
        
        return response['message'] ?? '';
      }
    } on DioException catch (e) {
      print('[AiDataSource] Chat DioException: ${e.message}');
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    } catch (e) {
      print('[AiDataSource] Chat unexpected error: $e');
      throw ServerException('Ошибка чата: $e');
    }
  }
}
