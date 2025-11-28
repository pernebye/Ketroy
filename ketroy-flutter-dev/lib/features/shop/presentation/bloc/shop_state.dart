part of 'shop_bloc.dart';

enum ShopStatus { initial, loading, success, failure }

class ShopState extends Equatable {
  final ShopStatus status;
  final List<ShopEntity> shopList;
  final List<CityEntity> cityList;
  final String? id;

  const ShopState(
      {this.status = ShopStatus.initial,
      this.shopList = const [],
      this.cityList = const [],
      this.id});

  @override
  List<Object?> get props => [status, shopList, cityList, id];

  bool get isInitial => status == ShopStatus.initial;
  bool get isLoading => status == ShopStatus.loading;
  bool get isSuccess => status == ShopStatus.success;
  bool get isFailure => status == ShopStatus.failure;

  ShopState copyWith(
      {ShopStatus? status,
      List<ShopEntity>? shopList,
      List<CityEntity>? cityList,
      String? id}) {
    return ShopState(
        status: status ?? this.status,
        shopList: shopList ?? this.shopList,
        cityList: cityList ?? this.cityList,
        id: id ?? this.id);
  }
}
