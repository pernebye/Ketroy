import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/bonus/data/models/bonus_programs_model.dart';
import 'package:ketroy_app/features/bonus/domain/repository/bonus_repository.dart';

class GetBonuses implements UseCase<List<BonusProgramsModel>, NoParams> {
  final BonusRepository bonusRepository;

  GetBonuses(this.bonusRepository);
  @override
  Future<Either<Failure, List<BonusProgramsModel>>> call(
      NoParams params, String? path) async {
    return await bonusRepository.getBonusPrograms();
  }
}
