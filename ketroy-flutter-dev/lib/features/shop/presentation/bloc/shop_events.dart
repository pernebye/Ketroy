part of 'shop_bloc.dart';

abstract class ShopEvent extends Equatable {
  const ShopEvent();

  @override
  List<Object> get props => [];
}

class GetShopListFetch extends ShopEvent {
  final String? city;

  const GetShopListFetch({required this.city});
}

class GetCityListFetch extends ShopEvent {}
