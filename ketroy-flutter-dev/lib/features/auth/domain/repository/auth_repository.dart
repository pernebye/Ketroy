import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/auth/data/models/register_answer_model.dart';
import 'package:ketroy_app/features/auth/data/models/verify_code_response_model.dart';
import 'package:ketroy_app/features/auth/domain/entities/auth_answer.dart';
import 'package:ketroy_app/features/auth/domain/entities/city_entity.dart';
import 'package:ketroy_app/features/auth/domain/entities/country_codes_entity.dart';
import 'package:ketroy_app/features/auth/domain/entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, AuthAnswer>> loginWithSms(
      {required String code, required String phone, required String sms});

  /// Отправка кода для регистрации
  Future<Either<Failure, VerifyCodeResponseModel>> sendVerifyCode(
      {required String phone, required String countryCode});

  /// Отправка кода для входа
  Future<Either<Failure, VerifyCodeResponseModel>> loginSendCode(
      {required String phone, required String countryCode});

  Future<Either<Failure, RegisterAnswerModel>> signUpWithPhone({
    required String name,
    required String surname,
    required String phone,
    required String code,
    required String? deviceToken,
    required String birthDate,
    required String city,
    required String height,
    required String clothingSize,
    required String shoeSize,
  });

  Future<Either<Failure, List<CountryCodesEntity>>> countryCodesRep();

  Future<Either<Failure, List<CityEntity>>> cityNamesRep();

  Future<Either<Failure, AuthUserEntity>> updateUser(
      {required String city,
      required String birthDate,
      required String height,
      required String clothingSize,
      required String shoeSize});

  // Future<Either<Failure, AuthUserEntity>> getProfileUser();
}
