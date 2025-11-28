part of 'shop_detail_bloc.dart';

abstract class ShopDetailEvent extends Equatable {
  const ShopDetailEvent();

  @override
  List<Object> get props => [];
}

class GetShopReviewFetch extends ShopDetailEvent {
  final int shopId;

  const GetShopReviewFetch({required this.shopId});
}

class SendShopReviewFetch extends ShopDetailEvent {
  final String shopId;
  final String userId;
  final String review;
  final String rating;

  const SendShopReviewFetch(
      {required this.shopId,
      required this.userId,
      required this.review,
      required this.rating});
}

class ResetSendSuccessEvent extends ShopDetailEvent {}
