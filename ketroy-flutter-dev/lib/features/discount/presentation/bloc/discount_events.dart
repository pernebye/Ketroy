part of 'discount_bloc.dart';

abstract class DiscountEvent extends Equatable {
  const DiscountEvent();

  @override
  List<Object> get props => [];
}

class GetPromoCodeFetch extends DiscountEvent {}

class PostPromoCodeFetch extends DiscountEvent {
  final String promoCode;

  const PostPromoCodeFetch({required this.promoCode});
}

class CheckReferralAvailability extends DiscountEvent {}

class LoadReferralInfo extends DiscountEvent {}

/// Сброс статуса после показа диалога
class ResetStatus extends DiscountEvent {}
