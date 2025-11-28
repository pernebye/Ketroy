import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/profile/domain/repository/profile_repository.dart';

class ProfileUpdateUser implements UseCase<String, ProfileUserParams> {
  final ProfileRepository profileRepository;
  ProfileUpdateUser(this.profileRepository);
  @override
  Future<Either<Failure, String>> call(
      ProfileUserParams params, String? path) async {
    return await profileRepository.updateUser(
        height: params.height,
        clothingSize: params.clothingSize,
        shoeSize: params.shoeSize,
        city: params.city,
        name: params.name,
        surname: params.surname,
        birthDay: params.birthDay);
  }
}

class ProfileUserParams {
  ProfileUserParams(
      {required this.height,
      required this.clothingSize,
      required this.shoeSize,
      required this.city,
      required this.name,
      required this.surname,
      required this.birthDay});
  final String height;
  final String clothingSize;
  final String shoeSize;
  final String city;
  final String name;
  final String surname;
  final String birthDay;
}
