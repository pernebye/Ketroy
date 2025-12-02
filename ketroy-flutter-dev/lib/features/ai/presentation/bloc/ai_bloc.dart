import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ketroy_app/features/ai/data/data_sources/ai_data_source.dart';
import 'package:ketroy_app/features/ai/data/models/chat_message_model.dart';
import 'package:ketroy_app/features/ai/domain/entities/ai_entity.dart';
import 'package:ketroy_app/features/ai/domain/use_cases/get_ai_response.dart';

part 'ai_events.dart';
part 'ai_state.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final GetAiResponse _getAiResponse;
  final AiDataSource _aiDataSource;

  AiBloc({
    required GetAiResponse getAiResponse,
    required AiDataSource aiDataSource,
  })  : _getAiResponse = getAiResponse,
        _aiDataSource = aiDataSource,
        super(const AiState()) {
    on<SendImageToServerFetch>(_sendImageToServerFetch);
    on<SendChatMessage>(_sendChatMessage);
    on<SendChatImage>(_sendChatImage);
    on<ClearChat>(_clearChat);
    on<CloseChat>(_closeChat);
  }

  /// Обработка первичного анализа изображения
  void _sendImageToServerFetch(
      SendImageToServerFetch event, Emitter<AiState> emit) async {
    debugPrint('🚀 AiBloc: Starting image analysis...');
    emit(state.copyWith(status: AiStatus.loading));

    final languageCode = event.languageCode ?? 'en';
    debugPrint('🌐 AiBloc: Language code: $languageCode');

    try {
      final res = await _getAiResponse(
        AiParams(imageFile: event.imageFile, languageCode: languageCode),
        null,
      );

      res.fold(
        (failure) {
          debugPrint('❌ AiBloc: Failure - ${failure.message}');
          emit(
            state.copyWith(status: AiStatus.failure, message: failure.message),
          );
        },
        (analyzeData) {
          debugPrint('✅ AiBloc: Success - Analysis received');
          // Создаём начальные сообщения чата
          final userMessage = ChatMessage.user(
            content: event.userMessage ?? 'Analyze this label',
            imageFile: event.imageFile,
          );
          final assistantMessage = ChatMessage.assistant(
            content: analyzeData.analysis,
          );

          emit(state.copyWith(
            status: AiStatus.success,
            analyzeResult: analyzeData,
            chatMessages: [userMessage, assistantMessage],
            isChatActive: true,
          ));
        },
      );
    } catch (e) {
      debugPrint('❌ AiBloc: Uncaught exception - $e');
      emit(state.copyWith(
        status: AiStatus.failure, 
        message: 'Ошибка: $e',
      ));
    }
  }

  /// Отправка текстового сообщения в чат
  void _sendChatMessage(SendChatMessage event, Emitter<AiState> emit) async {
    if (event.message.trim().isEmpty) return;

    final languageCode = event.languageCode ?? 'en';
    debugPrint('💬 AiBloc: Sending chat message with language: $languageCode');

    // Добавляем сообщение пользователя
    final userMessage = ChatMessage.user(content: event.message);
    final loadingMessage = ChatMessage.loading();

    emit(state.copyWith(
      chatMessages: [...state.chatMessages, userMessage, loadingMessage],
      isSendingMessage: true,
    ));

    try {
      final response = await _aiDataSource.sendChatMessage(
        message: event.message,
        chatHistory: state.chatMessages.where((m) => !m.isLoading).toList(),
        languageCode: languageCode,
      );

      // Заменяем loading на реальный ответ
      final assistantMessage = ChatMessage.assistant(content: response);
      final updatedMessages = state.chatMessages
          .where((m) => !m.isLoading)
          .toList()
        ..add(assistantMessage);

      emit(state.copyWith(
        chatMessages: updatedMessages,
        isSendingMessage: false,
      ));
    } catch (e) {
      // Убираем loading и показываем ошибку
      final errorMessage = ChatMessage.assistant(
        content: 'Произошла ошибка. Попробуйте ещё раз.',
      );
      final updatedMessages = state.chatMessages
          .where((m) => !m.isLoading)
          .toList()
        ..add(errorMessage);

      emit(state.copyWith(
        chatMessages: updatedMessages,
        isSendingMessage: false,
      ));
    }
  }

  /// Отправка изображения в чат
  void _sendChatImage(SendChatImage event, Emitter<AiState> emit) async {
    final languageCode = event.languageCode ?? 'en';
    final messageText = event.message ?? 'Проанализируй эту этикетку';
    debugPrint('📷 AiBloc: Sending chat image with language: $languageCode');

    // Добавляем сообщение пользователя с изображением
    final userMessage = ChatMessage.user(
      content: messageText,
      imageFile: event.imageFile,
    );
    final loadingMessage = ChatMessage.loading();

    emit(state.copyWith(
      chatMessages: [...state.chatMessages, userMessage, loadingMessage],
      isSendingMessage: true,
    ));

    try {
      final response = await _aiDataSource.sendChatMessage(
        message: messageText,
        chatHistory: state.chatMessages.where((m) => !m.isLoading).toList(),
        imageFile: event.imageFile,
        languageCode: languageCode,
      );

      final assistantMessage = ChatMessage.assistant(content: response);
      final updatedMessages = state.chatMessages
          .where((m) => !m.isLoading)
          .toList()
        ..add(assistantMessage);

      emit(state.copyWith(
        chatMessages: updatedMessages,
        isSendingMessage: false,
      ));
    } catch (e) {
      final errorMessage = ChatMessage.assistant(
        content: 'Не удалось обработать изображение. Попробуйте ещё раз.',
      );
      final updatedMessages = state.chatMessages
          .where((m) => !m.isLoading)
          .toList()
        ..add(errorMessage);

      emit(state.copyWith(
        chatMessages: updatedMessages,
        isSendingMessage: false,
      ));
    }
  }

  /// Очистить чат
  void _clearChat(ClearChat event, Emitter<AiState> emit) {
    emit(state.copyWith(
      chatMessages: [],
      analyzeResult: null,
      status: AiStatus.initial,
      isChatActive: false,
    ));
  }

  /// Закрыть чат и вернуться
  void _closeChat(CloseChat event, Emitter<AiState> emit) {
    emit(const AiState());
  }
}
