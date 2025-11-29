import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/profile/domain/repository/profile_repository.dart';

class UploadAvatar implements UseCase<String, UploadAvatarParams> {
  final ProfileRepository profileRepository;
  UploadAvatar(this.profileRepository);

  @override
  Future<Either<Failure, String>> call(
      UploadAvatarParams params, String? path) async {
    return await profileRepository.uploadAvatar(filePath: params.filePath);
  }
}

class UploadAvatarParams {
  final String filePath;

  UploadAvatarParams({required this.filePath});
}



