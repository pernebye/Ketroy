part of 'partners_bloc.dart';

enum PartnersStatus { initial, loading, success, failure }

class PartnersState extends Equatable {
  final PartnersStatus status;
  final String? amount;

  const PartnersState({
    this.status = PartnersStatus.initial,
    this.amount,
  });

  @override
  List<Object?> get props => [status, amount];

  bool get isInitial => status == PartnersStatus.initial;
  bool get isLoading => status == PartnersStatus.loading;
  bool get isSuccess => status == PartnersStatus.success;
  bool get isFailure => status == PartnersStatus.failure;

  PartnersState copyWith({
    PartnersStatus? status,
    String? amount,
  }) {
    return PartnersState(
      status: status ?? this.status,
      amount: amount ?? this.amount,
    );
  }
}
