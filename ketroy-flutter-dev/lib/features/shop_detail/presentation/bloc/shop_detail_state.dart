part of 'shop_detail_bloc.dart';

enum ShopDetailStatus { initial, loading, success, failure }

enum SendStatus { initial, loading, success, failure }

class ShopDetailState extends Equatable {
  final ShopDetailStatus status;
  final SendStatus sendStatus;
  final List<ShopReviewEntity> shopReviewList;
  final String? message;

  const ShopDetailState(
      {this.status = ShopDetailStatus.initial,
      this.sendStatus = SendStatus.initial,
      this.shopReviewList = const [],
      this.message});

  @override
  List<Object?> get props => [status, sendStatus, shopReviewList, message];

  bool get isInitial => status == ShopDetailStatus.initial;
  bool get isLoading => status == ShopDetailStatus.loading;
  bool get isSuccess => status == ShopDetailStatus.success;
  bool get isFailure => status == ShopDetailStatus.failure;

  bool get isSendInitial => sendStatus == SendStatus.initial;
  bool get isSendLoading => sendStatus == SendStatus.loading;
  bool get isSendSuccess => sendStatus == SendStatus.success;
  bool get isSendFailure => sendStatus == SendStatus.failure;

  ShopDetailState copyWith(
      {ShopDetailStatus? status,
      SendStatus? sendStatus,
      List<ShopReviewEntity>? shopReviewList,
      String? message}) {
    return ShopDetailState(
        status: status ?? this.status,
        sendStatus: sendStatus ?? this.sendStatus,
        shopReviewList: shopReviewList ?? this.shopReviewList,
        message: message ?? this.message);
  }
}
