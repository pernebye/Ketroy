import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/profile/domain/entities/discount_entity.dart';
import 'package:ketroy_app/features/profile/domain/repository/profile_repository.dart';

class GetDiscount implements UseCase<DiscountEntity, GetDiscountParams> {
  final ProfileRepository profileRepository;

  GetDiscount({required this.profileRepository});
  @override
  Future<Either<Failure, DiscountEntity>> call(
      GetDiscountParams params, String? path) async {
    return await profileRepository.getDiscount(token: params.token);
  }
}

class GetDiscountParams {
  final String? token;

  GetDiscountParams({required this.token});
}
