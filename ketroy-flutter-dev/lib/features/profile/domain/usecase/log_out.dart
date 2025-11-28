import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/profile/domain/repository/profile_repository.dart';

class LogOut implements UseCase<String, NoParams> {
  final ProfileRepository profileRepository;

  LogOut({required this.profileRepository});
  @override
  Future<Either<Failure, String>> call(NoParams params, String? path) async {
    return await profileRepository.logOut();
  }
}
