part of 'bonus_bloc.dart';

enum BonusStatus { initial, loading, success, failure }

class BonusState extends Equatable {
  final BonusStatus status;
  final List<BonusProgramsModel> bonuses;
  final String? message;

  const BonusState(
      {this.status = BonusStatus.initial,
      this.bonuses = const [],
      this.message});

  @override
  List<Object?> get props => [status, bonuses, message];

  bool get isInitial => status == BonusStatus.initial;
  bool get isLoading => status == BonusStatus.loading;
  bool get isSuccess => status == BonusStatus.success;
  bool get isFailure => status == BonusStatus.failure;

  BonusState copyWith({
    BonusStatus? status,
    List<BonusProgramsModel>? bonuses,
    String? message,
  }) {
    return BonusState(
        status: status ?? this.status,
        bonuses: bonuses ?? this.bonuses,
        message: message ?? this.message);
  }
}
