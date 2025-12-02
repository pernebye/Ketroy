import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ketroy_app/core/internet_services/dio_client.dart';
import 'package:ketroy_app/core/internet_services/error/dio_exception.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/paths.dart';
import 'package:ketroy_app/features/ai/data/models/ai_model.dart';
import 'package:ketroy_app/features/ai/data/models/chat_message_model.dart';

abstract interface class AiDataSource {
  Future<AiModel> getAiResponseData({
    required File imageFile,
    String languageCode = 'en',
  });
  Future<String> sendChatMessage({
    required String message,
    required List<ChatMessage> chatHistory,
    File? imageFile,
    String languageCode = 'en',
  });
}

class AiDataSourceImpl implements AiDataSource {
  @override
  Future<AiModel> getAiResponseData({
    required File imageFile,
    String languageCode = 'en',
  }) async {
    try {
      // Создаем FormData с файлом и language_code
      // НЕ отправляем поле 'language' - бэкенд его не принимает
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        'language_code': languageCode,
      });

      debugPrint('🔍 AI Scanner: Sending image to server with language_code: $languageCode');
      final response = await DioClient.instance
          .postFormData(clothingAnalyze, data: formData, tokenNeed: true);
      debugPrint('✅ AI Scanner: Response received: $response');
      return AiModel.fromjson(response);
    } on DioException catch (e) {
      debugPrint('❌ AI Scanner: DioException: ${e.message}');
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    } catch (e) {
      debugPrint('❌ AI Scanner: Unknown error: $e');
      throw ServerException('Ошибка анализа изображения: $e');
    }
  }

  @override
  Future<String> sendChatMessage({
    required String message,
    required List<ChatMessage> chatHistory,
    File? imageFile,
    String languageCode = 'en',
  }) async {
    try {
      // НЕ отправляем поле 'language' - бэкенд его не принимает
      final Map<String, dynamic> requestData = {
        'message': message,
        'language_code': languageCode,
        'chat_history': chatHistory
            .where((m) => !m.isLoading)
            .map((m) => {
                  'role': m.role.name,
                  'content': m.content,
                })
            .toList(),
      };

      debugPrint('💬 AI Chat: Sending message with language_code: $languageCode');

      // Если есть изображение, используем FormData
      if (imageFile != null) {
        final formData = FormData.fromMap({
          ...requestData,
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        });

        final response = await DioClient.instance
            .postFormData(clothingChat, data: formData, tokenNeed: true);
        return response['response'] ?? response['message'] ?? '';
      }

      // Без изображения - обычный POST
      final response = await DioClient.instance
          .post(clothingChat, data: requestData, tokenNeed: true);
      return response['response'] ?? response['message'] ?? '';
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }
}