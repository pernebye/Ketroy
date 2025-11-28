import 'package:dio/dio.dart';
import 'package:ketroy_app/core/internet_services/dio_client.dart';
import 'package:ketroy_app/core/internet_services/error/dio_exception.dart';
import 'package:ketroy_app/core/internet_services/paths.dart';
import 'package:ketroy_app/features/shop_detail/data/models/shop_review_model.dart';

abstract interface class ShopDetailDataSources {
  Future<List<ShopReviewModel>> getShopReview({required int shopId});
  Future<String> sendReview(
      {required String shopId,
      required String userId,
      required String review,
      required String rating});
}

class ShopDetailDataSourcesImpl implements ShopDetailDataSources {
  @override
  Future<List<ShopReviewModel>> getShopReview({required int shopId}) async {
    try {
      final response = await DioClient.instance
          .getList(reviews, queryParameters: {'shop_id': shopId});
      return response
          .map((reviewList) => ShopReviewModel.fromJson(reviewList))
          .toList();
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw error.errorMessage;
    }
  }

  @override
  Future<String> sendReview(
      {required String shopId,
      required String userId,
      required String review,
      required String rating}) async {
    try {
      final response = await DioClient.instance.post(reviews, data: {
        'shop_id': shopId,
        'user_id': userId,
        'review': review,
        'rating': rating
      });
      return response['message'];
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw error.errorMessage;
    }
  }
}
