import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/loyalty/domain/entities/loyalty_info_entity.dart';
import 'package:ketroy_app/features/loyalty/domain/repository/loyalty_repository.dart';

/// Use case для получения информации о лояльности
class GetLoyaltyInfo implements UseCase<LoyaltyInfoEntity, NoParams> {
  final LoyaltyRepository loyaltyRepository;

  GetLoyaltyInfo({required this.loyaltyRepository});

  @override
  Future<Either<Failure, LoyaltyInfoEntity>> call(NoParams params, String? path) {
    return loyaltyRepository.getLoyaltyInfo();
  }
}
