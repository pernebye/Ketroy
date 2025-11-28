import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/profile/data/promotion_model.dart';
import 'package:ketroy_app/features/profile/domain/repository/profile_repository.dart';

class GetPromotions implements UseCase<List<PromotionModel>, NoParams> {
  final ProfileRepository repository;

  GetPromotions(this.repository);

  @override
  Future<Either<Failure, List<PromotionModel>>> call(
      NoParams params, String? path) async {
    return await repository.getPromotions();
  }
}

