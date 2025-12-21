import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/loyalty/domain/repository/loyalty_repository.dart';

/// Use case для отметки достижений как просмотренных
class MarkLevelsViewed implements UseCase<int, NoParams> {
  final LoyaltyRepository loyaltyRepository;

  MarkLevelsViewed({required this.loyaltyRepository});

  @override
  Future<Either<Failure, int>> call(NoParams params, String? path) {
    return loyaltyRepository.markLevelsViewed();
  }
}
