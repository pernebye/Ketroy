import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/bonus/data/data_source/bonus_data_source.dart';
import 'package:ketroy_app/features/bonus/data/models/bonus_programs_model.dart';
import 'package:ketroy_app/features/bonus/domain/repository/bonus_repository.dart';

class BonusRepositoryImpl implements BonusRepository {
  final BonusDataSource bonusDataSource;
  BonusRepositoryImpl(this.bonusDataSource);
  @override
  Future<Either<Failure, List<BonusProgramsModel>>> getBonusPrograms() async {
    return _getBonuses(() async => await bonusDataSource.getBonusPrograms());
  }

  Future<Either<Failure, List<BonusProgramsModel>>> _getBonuses(
      Future<List<BonusProgramsModel>> Function() fn) async {
    try {
      final stats = await fn();
      return right(stats);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
