import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/shop_detail/domain/repositories/shop_detail_repository.dart';

class SendShopReview implements UseCase<String, SendShopReviewParams> {
  final ShopDetailRepository shopDetailRepository;
  SendShopReview(this.shopDetailRepository);

  @override
  Future<Either<Failure, String>> call(
      SendShopReviewParams params, String? path) async {
    return await shopDetailRepository.sendReviewRepo(
        shopId: params.shopId,
        userId: params.userId,
        review: params.review,
        rating: params.rating);
  }
}

class SendShopReviewParams {
  SendShopReviewParams(
      {required this.shopId,
      required this.userId,
      required this.review,
      required this.rating});
  final String shopId;
  final String userId;
  final String review;
  final String rating;
}
