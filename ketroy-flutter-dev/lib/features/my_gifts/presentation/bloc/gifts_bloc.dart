import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/my_gifts/data/data_source/gift_data_source.dart';
import 'package:ketroy_app/features/my_gifts/domain/entities/gifts_entities.dart';
import 'package:ketroy_app/features/my_gifts/domain/use_cases/activate_gift.dart';
import 'package:ketroy_app/features/my_gifts/domain/use_cases/get_gifts_list.dart';
import 'package:ketroy_app/features/my_gifts/domain/use_cases/save_gift.dart';
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';

part 'gifts_events.dart';
part 'gifts_state.dart';

class GiftsBloc extends Bloc<GiftsEvent, GiftsState> {
  final GetGiftsList _getGiftsList;
  final ActivateGift _activateGift;
  final SaveGift _saveGift;
  GiftsBloc(
      {required GetGiftsList getGiftsList,
      required ActivateGift activateGift,
      required SaveGift saveGift})
      : _getGiftsList = getGiftsList,
        _activateGift = activateGift,
        _saveGift = saveGift,
        super(const GiftsState()) {
    on<GetGiftsListFetch>(_getGiftsListFetch);
    on<ActivateGiftFetch>(_activateGiftFetch);
    on<SaveGiftFetch>(_saveGiftFetch);
    on<ResetStateFetch>(_resetStateFetch);
  }

  void _getGiftsListFetch(
      GetGiftsListFetch event, Emitter<GiftsState> emit) async {
    // Устанавливаем статус загрузки
    emit(state.copyWith(status: GiftsStatus.loading));
    
    final user = await UserDataManager.getUser();

    emit(state.copyWith(
        status: GiftsStatus.loading,
        name: user?.name,
        surname: user?.surname,
        avaImage: user?.avatarImage?.toString()));

    final res = await _getGiftsList(NoParams(), null);
    res.fold((failure) {
      emit(state.copyWith(
          status: GiftsStatus.failure, message: failure.message));
    }, (response) {
      final savedGiftsList =
          response.gifts.where((gift) => gift.isViewed == 1).toList();
      final gifts = response.gifts.where((gift) => gift.isViewed == 0).toList();
      emit(state.copyWith(
          status: GiftsStatus.success,
          giftsList: savedGiftsList,
          gifts: gifts,
          pendingGroups: response.pendingGroups,
          hasPending: response.hasPending));
    });
  }

  void _activateGiftFetch(
      ActivateGiftFetch event, Emitter<GiftsState> emit) async {
    emit(state.copyWith(isActivate: false));
    final res =
        await _activateGift(ActivateGiftParams(giftId: event.giftId), null);
    res.fold((failure) {
      emit(state.copyWith(message: failure.message));
    }, (success) {
      emit(state.copyWith(message: success, isActivate: true));
    });
  }

  void _saveGiftFetch(SaveGiftFetch event, Emitter<GiftsState> emit) async {
    emit(state.copyWith(isSaved: false));
    final res = await _saveGift(SaveGiftParams(giftId: event.giftId), null);
    res.fold((failure) {
      emit(state.copyWith(message: failure.message));
    }, (success) {
      emit(state.copyWith(message: success, isSaved: true));
    });
  }

  void _resetStateFetch(ResetStateFetch evetn, Emitter<GiftsState> emit) async {
    emit(state.copyWith(isSaved: false, isActivate: false));
  }
}
