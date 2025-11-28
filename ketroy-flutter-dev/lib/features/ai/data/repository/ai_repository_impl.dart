import 'dart:io';

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
  Future<Either<Failure, AiEntity>> getAiResponse(File imageFile) async {
    return await _getAiResponse(
        () async => await aiDataSource.getAiResponseData(imageFile: imageFile));
  }

  Future<Either<Failure, AiEntity>> _getAiResponse(
      Future<AiEntity> Function() fn) async {
    try {
      final result = await fn();
      return right(result);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
