import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/bonus/data/models/bonus_programs_model.dart';

abstract interface class BonusRepository {
  Future<Either<Failure, List<BonusProgramsModel>>> getBonusPrograms();
}
