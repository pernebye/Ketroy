import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/ai/data/data_sources/ai_data_source.dart';
import 'package:ketroy_app/features/ai/domain/entities/ai_entity.dart';
import 'package:ketroy_app/features/ai/domain/repository/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  final AiDataSource aiDataSource;

  AiRepositoryImpl({required this.aiDataSource});

  @override
  Future<Either<Failure, AiEntity>> getAiResponse(File imageFile, {String? languageCode}) async {
    return await _getAiResponse(
        () async => await aiDataSource.getAiResponseData(
          imageFile: imageFile,
          languageCode: languageCode ?? 'en',
        ));
  }

  Future<Either<Failure, AiEntity>> _getAiResponse(
      Future<AiEntity> Function() fn) async {
    try {
      final result = await fn();
      return right(result);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      // Ловим все остальные исключения
      debugPrint('❌ AI Repository: Unexpected error: $e');
      return left(Failure('Непредвиденная ошибка: $e'));
    }
  }
}
