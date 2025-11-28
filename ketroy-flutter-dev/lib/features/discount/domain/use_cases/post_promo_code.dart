import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/discount/domain/repository/discount_repository.dart';

class PostPromoCode implements UseCase<String, PostPromoCodeParams> {
  final DiscountRepository discountRepository;
  PostPromoCode({required this.discountRepository});

  @override
  Future<Either<Failure, String>> call(
      PostPromoCodeParams params, String? path) async {
    return await discountRepository.postPromoCode(promoCode: params.promoCode);
  }
}

class PostPromoCodeParams {
  final String promoCode;

  PostPromoCodeParams({required this.promoCode});
}
