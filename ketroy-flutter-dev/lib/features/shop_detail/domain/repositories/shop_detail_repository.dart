import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/shop_detail/domain/entities/shop_review_entity.dart';

abstract interface class ShopDetailRepository {
  Future<Either<Failure, List<ShopReviewEntity>>> getShopReviewRepo(
      {required int shopId});
  Future<Either<Failure, String>> sendReviewRepo(
      {required String shopId,
      required String userId,
      required String review,
      required String rating});
}
