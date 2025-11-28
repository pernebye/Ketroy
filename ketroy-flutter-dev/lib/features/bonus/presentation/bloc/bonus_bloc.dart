import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/bonus/data/models/bonus_programs_model.dart';
import 'package:ketroy_app/features/bonus/domain/usecases/get_bonuses.dart';

part 'bonus_events.dart';
part 'bonus_state.dart';

class BonusBloc extends Bloc<BonusEvent, BonusState> {
  final GetBonuses _getBonuses;
  BonusBloc({required GetBonuses getBonuses})
      : _getBonuses = getBonuses,
        super(const BonusState()) {
    on<GetBonussesFetch>(_getBonusesFetch);
  }

  void _getBonusesFetch(
      GetBonussesFetch event, Emitter<BonusState> emit) async {
    try {
      final res = await _getBonuses(NoParams(), null);
      res.fold(
          (failure) => emit(state.copyWith(
              status: BonusStatus.failure,
              message: failure.message)), (bonuses) {
        emit(state.copyWith(bonuses: bonuses, status: BonusStatus.success));
      });
    } catch (e) {
      emit(state.copyWith(
        status: BonusStatus.failure,
        message: 'Failed to load categories: ${e.toString()}',
      ));
    }
  }
}
