import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ketroy_app/features/ai/domain/entities/ai_entity.dart';
import 'package:ketroy_app/features/ai/domain/use_cases/get_ai_response.dart';

part 'ai_events.dart';
part 'ai_state.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final GetAiResponse _getAiResponse;
  AiBloc({required GetAiResponse getAiResponse})
      : _getAiResponse = getAiResponse,
        super(const AiState()) {
    on<SendImageToServerFetch>(_sendImageToServerFetch);
  }

  void _sendImageToServerFetch(
      SendImageToServerFetch event, Emitter<AiState> emit) async {
    emit(state.copyWith(status: AiStatus.loading));

    final res =
        await _getAiResponse(AiParams(imageFile: event.imageFile), null);

    res.fold(
        (failure) => emit(
            state.copyWith(status: AiStatus.failure, message: failure.message)),
        (analyzeData) {
      emit(
          state.copyWith(status: AiStatus.success, analyzeResult: analyzeData));
    });
  }
}
