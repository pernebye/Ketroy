part of 'ai_bloc.dart';

enum AiStatus { initial, loading, success, failure }

class AiState extends Equatable {
  final AiStatus status;
  final AiEntity? analyzeResult;
  final String? message;

  const AiState(
      {this.status = AiStatus.initial, this.analyzeResult, this.message});

  @override
  List<Object?> get props => [status, analyzeResult, message];

  bool get isInitial => status == AiStatus.initial;
  bool get isLoading => status == AiStatus.loading;
  bool get isSuccess => status == AiStatus.success;
  bool get isFailure => status == AiStatus.failure;

  AiState copyWith({
    AiStatus? status,
    AiEntity? analyzeResult,
    String? message,
  }) {
    return AiState(
        status: status ?? this.status,
        analyzeResult: analyzeResult ?? this.analyzeResult,
        message: message ?? this.message);
  }
}
