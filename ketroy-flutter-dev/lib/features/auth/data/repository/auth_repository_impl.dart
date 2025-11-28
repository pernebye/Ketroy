import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/auth/data/data_source/auth_api_service.dart';
import 'package:ketroy_app/features/auth/data/models/register_answer_model.dart';
import 'package:ketroy_app/features/auth/data/models/verify_code_response_model.dart';
import 'package:ketroy_app/features/auth/domain/entities/auth_answer.dart';
import 'package:ketroy_app/features/auth/domain/entities/city_entity.dart';
import 'package:ketroy_app/features/auth/domain/entities/country_codes_entity.dart';
import 'package:ketroy_app/features/auth/domain/entities/user_entity.dart';
import 'package:ketroy_app/features/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService apiService;
  AuthRepositoryImpl(this.apiService);
  @override
  Future<Either<Failure, AuthAnswer>> loginWithSms(
      {required String code, required String phone, required String sms}) {
    return _loginWithSms(() async =>
        await apiService.loginWithSms(code: code, phone: phone, sms: sms));
  }

  Future<Either<Failure, AuthAnswer>> _loginWithSms(
      Future<AuthAnswer> Function() fn) async {
    try {
      final authAnswer = await fn();
      return right(authAnswer);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, VerifyCodeResponseModel>> sendVerifyCode(
      {required String phone, required String countryCode}) {
    return _sendVerifyCodeResponse(() async => await apiService.sendVerifyCode(
        phone: phone, countryCode: countryCode));
  }

  @override
  Future<Either<Failure, VerifyCodeResponseModel>> loginSendCode(
      {required String phone, required String countryCode}) {
    return _sendVerifyCodeResponse(() async =>
        await apiService.loginSendCode(phone: phone, countryCode: countryCode));
  }

  Future<Either<Failure, VerifyCodeResponseModel>> _sendVerifyCodeResponse(
      Future<VerifyCodeResponseModel> Function() fn) async {
    try {
      final data = await fn();
      return right(data);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, RegisterAnswerModel>> signUpWithPhone(
      {required String name,
      required String surname,
      required String phone,
      required String code,
      required String? deviceToken,
      required String birthDate,
      required String city,
      required String height,
      required String clothingSize,
      required String shoeSize}) async {
    return _signUpWithPhone(() async => await apiService.signUpUsers(
        name: name,
        surname: surname,
        phone: phone,
        code: code,
        deviceToken: deviceToken,
        birthDate: birthDate,
        city: city,
        height: height,
        clothingSize: clothingSize,
        shoeSize: shoeSize));
  }

  Future<Either<Failure, RegisterAnswerModel>> _signUpWithPhone(
      Future<RegisterAnswerModel> Function() fn) async {
    try {
      final data = await fn();
      return right(data);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CountryCodesEntity>>> countryCodesRep() async {
    return _countryCodesRep(() async => await apiService.countryCodes());
  }

  Future<Either<Failure, List<CountryCodesEntity>>> _countryCodesRep(
      Future<List<CountryCodesEntity>> Function() fn) async {
    try {
      final data = await fn();
      return right(data);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CityEntity>>> cityNamesRep() async {
    return _cityNamesRep(() async => await apiService.cityNames());
  }

  Future<Either<Failure, List<CityEntity>>> _cityNamesRep(
      Future<List<CityEntity>> Function() fn) async {
    try {
      final data = await fn();
      return right(data);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, AuthUserEntity>> updateUser(
      {required String city,
      required String birthDate,
      required String height,
      required String clothingSize,
      required String shoeSize}) async {
    return _updateUser(() async => await apiService.updateUser(
        city: city,
        birthDate: birthDate,
        height: height,
        clothingSize: clothingSize,
        shoeSize: shoeSize));
  }

  Future<Either<Failure, AuthUserEntity>> _updateUser(
      Future<AuthUserEntity> Function() fn) async {
    try {
      final data = await fn();
      return right(data);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  // @override
  // Future<Either<Failure, AuthUserEntity>> getProfileUser() async {
  //   return _getProfileUser(() async => await apiService.getUserData());
  // }

  // Future<Either<Failure, AuthUserEntity>> _getProfileUser(
  //     Future<AuthUserEntity> Function() fn) async {
  //   try {
  //     final stats = await fn();
  //     return right(stats);
  //   } on ServerException catch (e) {
  //     return left(Failure(e.message));
  //   }
  // }
}
