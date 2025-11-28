import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ketroy_app/features/discount/domain/entities/referral_info.dart';
import 'package:ketroy_app/features/discount/domain/repository/discount_repository.dart';
import 'package:ketroy_app/features/discount/domain/use_cases/post_promo_code.dart';
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';

part 'discount_events.dart';
part 'discount_state.dart';

class DiscountBloc extends Bloc<DiscountEvent, DiscountState> {
  final PostPromoCode _postPromoCode;
  final DiscountRepository _discountRepository;

  DiscountBloc({
    required PostPromoCode postPromoCode,
    required DiscountRepository discountRepository,
  })  : _postPromoCode = postPromoCode,
        _discountRepository = discountRepository,
        super(const DiscountState()) {
    on<GetPromoCodeFetch>(_getPromoCodeFetch);
    on<PostPromoCodeFetch>(_postPromoCodeFetch);
    on<CheckReferralAvailability>(_checkReferralAvailability);
    on<LoadReferralInfo>(_loadReferralInfo);
    on<ResetStatus>(_resetStatus);
  }
  
  void _resetStatus(ResetStatus event, Emitter<DiscountState> emit) {
    emit(state.copyWith(status: DiscountStatus.initial));
  }

  void _getPromoCodeFetch(
      GetPromoCodeFetch event, Emitter<DiscountState> emit) async {
    final user = await UserDataManager.getUser();
    final promoCode = user?.promoCode?.code;
    emit(state.copyWith(promoCode: promoCode));
  }

  void _postPromoCodeFetch(
      PostPromoCodeFetch event, Emitter<DiscountState> emit) async {
    emit(state.copyWith(status: DiscountStatus.initial));
    final res = await _postPromoCode(
        PostPromoCodeParams(promoCode: event.promoCode), null);
    res.fold((failure) {
      emit(state.copyWith(
          status: DiscountStatus.failure, message: failure.message));
    }, (successMessage) {
      emit(state.copyWith(
          status: DiscountStatus.success, message: successMessage));
    });
  }

  void _checkReferralAvailability(
      CheckReferralAvailability event, Emitter<DiscountState> emit) async {
    final isAvailable = await _discountRepository.checkReferralAvailability();
    emit(state.copyWith(isReferralAvailable: isAvailable));
  }
  
  void _loadReferralInfo(
      LoadReferralInfo event, Emitter<DiscountState> emit) async {
    final result = await _discountRepository.getReferralInfo();
    result.fold(
      (failure) {
        emit(state.copyWith(isReferralAvailable: false));
      },
      (info) {
        emit(state.copyWith(
          referralInfo: info,
          isReferralAvailable: info.isAvailable,
          promoCode: info.promoCode,
        ));
      },
    );
  }
}
