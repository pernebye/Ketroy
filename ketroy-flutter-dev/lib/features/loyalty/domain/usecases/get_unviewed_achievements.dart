import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/loyalty/data/models/loyalty_info_model.dart';
import 'package:ketroy_app/features/loyalty/domain/repository/loyalty_repository.dart';

/// Use case для получения непросмотренных достижений
class GetUnviewedAchievements implements UseCase<UnviewedLevelsResponse, NoParams> {
  final LoyaltyRepository loyaltyRepository;

  GetUnviewedAchievements({required this.loyaltyRepository});

  @override
  Future<Either<Failure, UnviewedLevelsResponse>> call(NoParams params, String? path) {
    return loyaltyRepository.getUnviewedAchievements();
  }
}
