part of 'ai_bloc.dart';

enum AiStatus { initial, loading, success, failure }

class AiState extends Equatable {
  final AiStatus status;
  final AiEntity? analyzeResult;
  final String? message;
  final List<ChatMessage> chatMessages;
  final bool isChatActive;
  final bool isSendingMessage;

  const AiState({
    this.status = AiStatus.initial,
    this.analyzeResult,
    this.message,
    this.chatMessages = const [],
    this.isChatActive = false,
    this.isSendingMessage = false,
  });

  @override
  List<Object?> get props => [status, analyzeResult, message, chatMessages, isChatActive, isSendingMessage];

  bool get isInitial => status == AiStatus.initial;
  bool get isLoading => status == AiStatus.loading;
  bool get isSuccess => status == AiStatus.success;
  bool get isFailure => status == AiStatus.failure;

  AiState copyWith({
    AiStatus? status,
    AiEntity? analyzeResult,
    String? message,
    List<ChatMessage>? chatMessages,
    bool? isChatActive,
    bool? isSendingMessage,
  }) {
    return AiState(
      status: status ?? this.status,
      analyzeResult: analyzeResult ?? this.analyzeResult,
      message: message ?? this.message,
      chatMessages: chatMessages ?? this.chatMessages,
      isChatActive: isChatActive ?? this.isChatActive,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
    );
  }
}
