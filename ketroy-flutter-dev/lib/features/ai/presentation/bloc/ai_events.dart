part of 'ai_bloc.dart';

abstract class AiEvent extends Equatable {
  const AiEvent();

  @override
  List<Object> get props => [];
}

class InitialAiEvent extends AiEvent {}

/// Отправить изображение для первичного анализа
class SendImageToServerFetch extends AiEvent {
  final File imageFile;
  final String? languageCode;
  final String? userMessage;

  const SendImageToServerFetch({required this.imageFile, this.languageCode, this.userMessage});

  @override
  List<Object> get props => [imageFile, languageCode ?? '', userMessage ?? ''];
}

/// Отправить текстовое сообщение в чат
class SendChatMessage extends AiEvent {
  final String message;
  final String? languageCode;

  const SendChatMessage({required this.message, this.languageCode});

  @override
  List<Object> get props => [message, languageCode ?? ''];
}

/// Отправить изображение в чат (новая этикетка)
class SendChatImage extends AiEvent {
  final File imageFile;
  final String? message;
  final String? languageCode;

  const SendChatImage({required this.imageFile, this.message, this.languageCode});

  @override
  List<Object> get props => [imageFile, message ?? '', languageCode ?? ''];
}

/// Очистить чат и начать заново
class ClearChat extends AiEvent {}

/// Закрыть чат и вернуться к начальному экрану
class CloseChat extends AiEvent {}
