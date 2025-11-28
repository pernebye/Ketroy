import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/shop_detail/domain/entities/shop_review_entity.dart';
import 'package:ketroy_app/features/shop_detail/domain/repositories/shop_detail_repository.dart';

class GetShopReview
    implements UseCase<List<ShopReviewEntity>, GetShopReviewParams> {
  final ShopDetailRepository shopDetailRepository;
  GetShopReview(this.shopDetailRepository);

  @override
  Future<Either<Failure, List<ShopReviewEntity>>> call(
      GetShopReviewParams params, String? path) async {
    return await shopDetailRepository.getShopReviewRepo(shopId: params.shopId);
  }
}

class GetShopReviewParams {
  final int shopId;

  GetShopReviewParams({required this.shopId});
}
