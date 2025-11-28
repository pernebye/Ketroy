import 'package:dio/dio.dart';
import 'package:ketroy_app/core/internet_services/dio_client.dart';
import 'package:ketroy_app/core/internet_services/error/dio_exception.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/paths.dart';
import 'package:ketroy_app/features/auth/data/models/city_model.dart';
import 'package:ketroy_app/features/shop/data/models/shop_model.dart';

abstract interface class ShopDataSource {
  Future<List<ShopModel>> shopList({required String? city});
  Future<List<CityModel>> cityList();
}

class ShopDataSourceImpl implements ShopDataSource {
  @override
  Future<List<ShopModel>> shopList({required String? city}) async {
    try {
      final response = await DioClient.instance
          .getList(shop, queryParameters: {'city': city});
      return response.map((shopList) => ShopModel.fromjson(shopList)).toList();
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<List<CityModel>> cityList() async {
    try {
      final response = await DioClient.instance.getList(cityPath);
      return response.map((cityList) => CityModel.fromjson(cityList)).toList();
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }
}
