import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ketroy_app/core/internet_services/dio_client.dart';
import 'package:ketroy_app/core/internet_services/error/dio_exception.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/paths.dart';
import 'package:ketroy_app/features/news/data/models/actuals_model.dart';
import 'package:ketroy_app/features/news/data/models/banners_model.dart';
import 'package:ketroy_app/features/news/data/models/categories_model.dart';
import 'package:ketroy_app/features/news/data/models/news_list_model.dart';
import 'package:ketroy_app/features/news/data/models/news_model.dart';

abstract interface class NewsDataSource {
  Future<BannersModel> getBannersData({String? city});
  Future<NewsModel> getNewsList({
    String? category,
    int? page,
    String? city,
    String? clothingSize,
    String? shoeSize,
  });
  Future<NewsListModel> getNewsById({required int id});
  Future<List<CategoriesModel>> getCategories();
  Future<List<ActualsModel>> getActuals({required String city});
  Future<String> postDeviceToken({required String token});
}

class NewsDataSourceImpl implements NewsDataSource {
  @override
  Future<BannersModel> getBannersData({String? city}) async {
    try {
      final response = await DioClient.instance.get(
        banners,
        queryParameters: city != null && city.isNotEmpty ? {'city': city} : null,
        needToken: false,
      );
      return BannersModel.fromjson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<NewsModel> getNewsList({
    String? category,
    int? page,
    String? city,
    String? clothingSize,
    String? shoeSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (page != null) queryParams['page'] = page;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (clothingSize != null && clothingSize.isNotEmpty) {
        queryParams['clothing_size'] = clothingSize;
      }
      if (shoeSize != null && shoeSize.isNotEmpty) {
        queryParams['shoe_size'] = shoeSize;
      }
      
      final response = await DioClient.instance.get(
        news,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        needToken: false,
      );
      return NewsModel.fromjson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<List<CategoriesModel>> getCategories() async {
    try {
      final response =
          await DioClient.instance.getList(categories, needToken: false);
      return response
          .map((categories) => CategoriesModel.fromJson(categories))
          .toList();
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<List<ActualsModel>> getActuals({required String city}) async {
    try {
      final response = await DioClient.instance
          .getList(actuals, queryParameters: {'city': city});
      debugPrint('📥 Actuals API response: $response');
      return response.map((actuals) => ActualsModel.fromJson(actuals)).toList();
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<String> postDeviceToken({required String token}) async {
    try {
      final response = await DioClient.instance.post(deviceTokenPostUrl,
          data: {'device_token': token}, tokenNeed: true);
      return response['message'];
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<NewsListModel> getNewsById({required int id}) async {
    try {
      final response =
          await DioClient.instance.get('$news/$id', needToken: false);
      return NewsListModel.fromJson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }
}
