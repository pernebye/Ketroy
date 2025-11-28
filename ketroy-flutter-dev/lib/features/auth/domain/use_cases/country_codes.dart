import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/auth/domain/entities/country_codes_entity.dart';
import 'package:ketroy_app/features/auth/domain/repository/auth_repository.dart';

class CountryCodes implements UseCase<List<CountryCodesEntity>, NoParams> {
  final AuthRepository authRepository;
  CountryCodes(this.authRepository);
  @override
  Future<Either<Failure, List<CountryCodesEntity>>> call(
      NoParams params, String? path) async {
    return await authRepository.countryCodesRep();
  }
}
