import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/auth/domain/entities/city_entity.dart';
import 'package:ketroy_app/features/auth/domain/repository/auth_repository.dart';

class CityNames implements UseCase<List<CityEntity>, NoParams> {
  final AuthRepository authRepository;
  CityNames(this.authRepository);
  @override
  Future<Either<Failure, List<CityEntity>>> call(
      NoParams params, String? path) async {
    return await authRepository.cityNamesRep();
  }
}
