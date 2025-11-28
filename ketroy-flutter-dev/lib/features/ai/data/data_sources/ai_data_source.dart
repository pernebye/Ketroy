import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ketroy_app/core/internet_services/dio_client.dart';
import 'package:ketroy_app/core/internet_services/error/dio_exception.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/paths.dart';
import 'package:ketroy_app/features/ai/data/models/ai_model.dart';

abstract interface class AiDataSource {
  Future<AiModel> getAiResponseData({required File imageFile});
}

class AiDataSourceImpl implements AiDataSource {
  @override
  Future<AiModel> getAiResponseData({required File imageFile}) async {
    try {
      // Создаем FormData с файлом
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await DioClient.instance
          .postFormData(clothingAnalyze, data: formData, tokenNeed: true);
      return AiModel.fromjson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }
}
