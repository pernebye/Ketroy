import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/ai/domain/entities/ai_entity.dart';
import 'package:ketroy_app/features/ai/domain/repository/ai_repository.dart';

class GetAiResponse implements UseCase<AiEntity, AiParams> {
  final AiRepository aiRepository;

  GetAiResponse({required this.aiRepository});
  @override
  Future<Either<Failure, AiEntity>> call(AiParams params, String? path) async {
    return await aiRepository.getAiResponse(params.imageFile, languageCode: params.languageCode);
  }
}

class AiParams {
  final File imageFile;
  final String? languageCode;

  AiParams({required this.imageFile, this.languageCode});
}
