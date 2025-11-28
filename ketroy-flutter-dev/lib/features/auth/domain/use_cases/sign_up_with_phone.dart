import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/auth/data/models/register_answer_model.dart';
import 'package:ketroy_app/features/auth/domain/repository/auth_repository.dart';

class SignUpWithPhone
    implements UseCase<RegisterAnswerModel, SignUpWithPhoneParams> {
  final AuthRepository authRepository;
  SignUpWithPhone(this.authRepository);
  @override
  Future<Either<Failure, RegisterAnswerModel>> call(
      SignUpWithPhoneParams params, String? path) async {
    return await authRepository.signUpWithPhone(
        name: params.name,
        surname: params.surname,
        phone: params.phone,
        code: params.code,
        deviceToken: params.deviceToken,
        birthDate: params.birthDate,
        city: params.city,
        height: params.height,
        clothingSize: params.clothingSize,
        shoeSize: params.shoeSize);
  }
}

class SignUpWithPhoneParams {
  final String name;
  final String surname;
  final String phone;
  final String code;
  final String? deviceToken;
  final String birthDate;
  final String city;
  final String height;
  final String clothingSize;
  final String shoeSize;

  SignUpWithPhoneParams(
      {required this.name,
      required this.surname,
      required this.phone,
      required this.code,
      required this.deviceToken,
      required this.birthDate,
      required this.city,
      required this.height,
      required this.clothingSize,
      required this.shoeSize});
}
