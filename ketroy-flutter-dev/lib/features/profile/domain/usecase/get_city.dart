import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/profile/domain/entities/city_entity.dart';
import 'package:ketroy_app/features/profile/domain/repository/profile_repository.dart';

class GetCity implements UseCase<List<CityEntity>, NoParams> {
  final ProfileRepository profileRepository;
  GetCity(this.profileRepository);
  @override
  Future<Either<Failure, List<CityEntity>>> call(
      NoParams params, String? path) async {
    return await profileRepository.getCity();
  }
}
