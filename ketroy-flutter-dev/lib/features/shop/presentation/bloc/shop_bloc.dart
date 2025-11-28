import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/auth/domain/entities/city_entity.dart';
import 'package:ketroy_app/features/shop/domain/entities/shop_entity.dart';
import 'package:ketroy_app/features/shop/domain/usecases/get_city_list.dart';
import 'package:ketroy_app/features/shop/domain/usecases/get_shop_list.dart';
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';

part 'shop_events.dart';
part 'shop_state.dart';

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  final GetShopList _getShopList;
  final GetCityList _getCityList;
  ShopBloc({required GetShopList getShopList, required GetCityList getCityList})
      : _getShopList = getShopList,
        _getCityList = getCityList,
        super(const ShopState()) {
    on<GetShopListFetch>(_getShopListFetch);
    on<GetCityListFetch>(_getCityListFetch);
  }

  void _getShopListFetch(
      GetShopListFetch event, Emitter<ShopState> emit) async {
    final user = await UserDataManager.getUser();
    final res = await _getShopList(ShopParams(city: event.city), null);
    final userId = user?.id.toString();

    res.fold((failure) => emit(state.copyWith(status: ShopStatus.failure)),
        (shopList) {
      emit(state.copyWith(
          status: ShopStatus.success, shopList: shopList, id: userId));
    });
  }

  void _getCityListFetch(
      GetCityListFetch event, Emitter<ShopState> emit) async {
    final res = await _getCityList(NoParams(), null);
    res.fold((failure) => emit(state.copyWith()), (cityList) {
      emit(state.copyWith(cityList: cityList));
    });
  }
}
