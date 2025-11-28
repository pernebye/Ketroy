import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/profile/domain/repository/profile_repository.dart';

class DeleteUser implements UseCase<String, NoParams> {
  final ProfileRepository profileRepository;

  DeleteUser({required this.profileRepository});
  @override
  Future<Either<Failure, String>> call(NoParams params, String? path) async {
    return await profileRepository.deleteAccount();
  }
}
