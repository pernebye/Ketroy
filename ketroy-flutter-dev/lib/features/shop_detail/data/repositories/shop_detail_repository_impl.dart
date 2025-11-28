import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/shop_detail/data/data_source/shop_detail_data_sources.dart';
import 'package:ketroy_app/features/shop_detail/domain/entities/shop_review_entity.dart';
import 'package:ketroy_app/features/shop_detail/domain/repositories/shop_detail_repository.dart';

class ShopDetailRepositoryImpl implements ShopDetailRepository {
  final ShopDetailDataSources shopDetailDataSources;
  ShopDetailRepositoryImpl(this.shopDetailDataSources);
  @override
  Future<Either<Failure, List<ShopReviewEntity>>> getShopReviewRepo(
      {required int shopId}) async {
    return _getShopReviewRepo(
        () async => await shopDetailDataSources.getShopReview(shopId: shopId));
  }

  Future<Either<Failure, List<ShopReviewEntity>>> _getShopReviewRepo(
      Future<List<ShopReviewEntity>> Function() fn) async {
    try {
      final data = await fn();
      return right(data);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  Future<Either<Failure, String>> _sendReviewRepo(
      Future<String> Function() fn) async {
    try {
      final data = await fn();
      return right(data);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> sendReviewRepo(
      {required String shopId,
      required String userId,
      required String review,
      required String rating}) {
    return _sendReviewRepo(() async => await shopDetailDataSources.sendReview(
        shopId: shopId, userId: userId, review: review, rating: rating));
  }
}
