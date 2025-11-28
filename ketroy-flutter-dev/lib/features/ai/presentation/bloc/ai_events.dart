part of 'ai_bloc.dart';

abstract class AiEvent extends Equatable {
  const AiEvent();

  @override
  List<Object> get props => [];
}

class InitialAiEvent extends AiEvent {}

class SendImageToServerFetch extends AiEvent {
  final File imageFile;

  const SendImageToServerFetch({required this.imageFile});
}
