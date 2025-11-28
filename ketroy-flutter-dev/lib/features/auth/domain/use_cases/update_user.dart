import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/auth/domain/entities/user_entity.dart';
import 'package:ketroy_app/features/auth/domain/repository/auth_repository.dart';

class UpdateUser implements UseCase<AuthUserEntity, UserParams> {
  final AuthRepository authRepository;
  UpdateUser(this.authRepository);
  @override
  Future<Either<Failure, AuthUserEntity>> call(
      UserParams params, String? path) async {
    return authRepository.updateUser(
        city: params.city,
        birthDate: params.birthDate,
        height: params.height,
        clothingSize: params.clothingSize,
        shoeSize: params.shoeSize);
  }
}

class UserParams {
  UserParams(
      {required this.city,
      required this.birthDate,
      required this.height,
      required this.clothingSize,
      required this.shoeSize});
  final String city;
  final String birthDate;
  final String height;
  final String clothingSize;
  final String shoeSize;
}
