import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/partners/domain/use_cases/get_amount.dart';

part 'partners_events.dart';
part 'partners_state.dart';

class PartnersBloc extends Bloc<PartnersEvent, PartnersState> {
  final GetAmount _getAmount;
  PartnersBloc({required GetAmount getAmount})
      : _getAmount = getAmount,
        super(const PartnersState()) {
    on<GetAmountDataFetch>(_getAmountDataFetch);
  }

  void _getAmountDataFetch(
      GetAmountDataFetch event, Emitter<PartnersState> emit) async {
    final res = await _getAmount(NoParams(), null);
    res.fold((failure) => emit(state.copyWith(status: PartnersStatus.failure)),
        (amount) {
      emit(state.copyWith(status: PartnersStatus.success, amount: amount));
    });
  }
}
