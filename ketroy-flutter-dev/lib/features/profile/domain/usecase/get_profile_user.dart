import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/auth/domain/entities/user_entity.dart';
import 'package:ketroy_app/features/profile/domain/repository/profile_repository.dart';

class GetProfileUser implements UseCase<AuthUserEntity, NoParams> {
  final ProfileRepository profileRepository;
  GetProfileUser(this.profileRepository);
  @override
  Future<Either<Failure, AuthUserEntity>> call(
      NoParams params, String? path) async {
    return await profileRepository.getProfileUser();
  }
}
