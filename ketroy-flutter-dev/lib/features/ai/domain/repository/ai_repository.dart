import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/ai/domain/entities/ai_entity.dart';

abstract interface class AiRepository {
  Future<Either<Failure, AiEntity>> getAiResponse(File imageFile, {String? languageCode});
}
