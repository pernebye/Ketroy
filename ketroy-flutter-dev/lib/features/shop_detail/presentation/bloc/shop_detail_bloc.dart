import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ketroy_app/features/shop_detail/domain/entities/shop_review_entity.dart';
import 'package:ketroy_app/features/shop_detail/domain/usecases/get_shop_review.dart';
import 'package:ketroy_app/features/shop_detail/domain/usecases/send_shop_review.dart';

part 'shop_detail_events.dart';
part 'shop_detail_state.dart';

class ShopDetailBloc extends Bloc<ShopDetailEvent, ShopDetailState> {
  final GetShopReview _getShopReview;
  final SendShopReview _sendShopReview;
  ShopDetailBloc(
      {required GetShopReview getShopReview,
      required SendShopReview sendShopReview})
      : _getShopReview = getShopReview,
        _sendShopReview = sendShopReview,
        super(const ShopDetailState()) {
    on<GetShopReviewFetch>(_getShopReviewFetch);
    on<SendShopReviewFetch>(_sendShopReviewFetch);
    on<ShopDetailEvent>(
      (event, emit) => emit(state.copyWith(sendStatus: SendStatus.initial)),
    );
    on<ResetSendSuccessEvent>(
      (event, emit) => emit(state.copyWith(sendStatus: SendStatus.initial)),
    );
  }

  void _getShopReviewFetch(
      GetShopReviewFetch event, Emitter<ShopDetailState> emit) async {
    final res =
        await _getShopReview(GetShopReviewParams(shopId: event.shopId), null);
    res.fold(
        (failure) => emit(state.copyWith(status: ShopDetailStatus.failure)),
        (shopReviewList) {
      emit(state.copyWith(
          status: ShopDetailStatus.success,
          sendStatus: SendStatus.initial,
          shopReviewList: shopReviewList));
    });
  }

  void _sendShopReviewFetch(
      SendShopReviewFetch event, Emitter<ShopDetailState> emit) async {
    final res = await _sendShopReview(
        SendShopReviewParams(
            shopId: event.shopId,
            userId: event.userId,
            review: event.review,
            rating: event.rating),
        null);
    res.fold(
        (failure) => emit(state.copyWith(
            sendStatus: SendStatus.failure, message: failure.message)),
        (message) => emit(state.copyWith(sendStatus: SendStatus.success)));
  }
}
