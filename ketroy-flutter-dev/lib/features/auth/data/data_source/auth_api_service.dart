import 'package:dio/dio.dart';
import 'package:ketroy_app/core/internet_services/dio_client.dart';
import 'package:ketroy_app/core/internet_services/error/dio_exception.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/paths.dart';
import 'package:ketroy_app/features/auth/data/models/auth_answer_model.dart';
import 'package:ketroy_app/features/auth/data/models/city_model.dart';
import 'package:ketroy_app/features/auth/data/models/country_codes_model.dart';
import 'package:ketroy_app/features/auth/data/models/register_answer_model.dart';
import 'package:ketroy_app/features/auth/data/models/user_model.dart';
import 'package:ketroy_app/features/auth/data/models/verify_code_response_model.dart';

abstract interface class AuthApiService {
  Future<AuthAnswerModel> loginWithSms(
      {required String code, required String phone, required String sms});

  Future<List<CountryCodesModel>> countryCodes();

  /// Отправка кода для регистрации (возвращает user_exists)
  Future<VerifyCodeResponseModel> sendVerifyCode(
      {required String phone, required String countryCode});

  /// Отправка кода для входа (возвращает user_exists)
  Future<VerifyCodeResponseModel> loginSendCode(
      {required String phone, required String countryCode});

  Future<RegisterAnswerModel> signUpUsers(
      {required String name,
      required String surname,
      required String phone,
      required String code,
      required String? deviceToken,
      required String birthDate,
      required String city,
      required String height,
      required String clothingSize,
      required String shoeSize});

  Future<List<CityModel>> cityNames();
  Future<AuthUserModel> updateUser(
      {required String city,
      required String birthDate,
      required String height,
      required String clothingSize,
      required String shoeSize});

  // Future<AuthUserModel> getUserData();
}

class AuthApiServiceImpl implements AuthApiService {
  @override
  Future<AuthAnswerModel> loginWithSms(
      {required String code,
      required String phone,
      required String sms}) async {
    try {
      final response = await DioClient.instance.post(verifyCode, data: {
        'phone': phone,
        'country_code': code,
        'verification_code': sms
      });
      return AuthAnswerModel.fromJson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<VerifyCodeResponseModel> sendVerifyCode(
      {required String phone, required String countryCode}) async {
    try {
      final response = await DioClient.instance.post(sendVerifyCodePath,
          data: {'phone': phone, 'country_code': countryCode});
      return VerifyCodeResponseModel.fromJson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<VerifyCodeResponseModel> loginSendCode(
      {required String phone, required String countryCode}) async {
    try {
      final response = await DioClient.instance.post(loginSendCodePath,
          data: {'phone': phone, 'country_code': countryCode});
      return VerifyCodeResponseModel.fromJson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<RegisterAnswerModel> signUpUsers(
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
    try {
      final response = await DioClient.instance.post(register, data: {
        'name': name,
        'surname': surname,
        'phone': phone,
        'country_code': code,
        'device_token': deviceToken,
        'birthdate': birthDate,
        'city': city,
        'height': height,
        'clothing_size': clothingSize,
        'shoe_size': shoeSize
      });
      return RegisterAnswerModel.fromjson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<List<CountryCodesModel>> countryCodes() async {
    try {
      final response = await DioClient.instance.getList(countryCodesPath);
      return response
          .map((countryCodesList) =>
              CountryCodesModel.fromjson(countryCodesList))
          .toList();
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<List<CityModel>> cityNames() async {
    try {
      final response = await DioClient.instance.getList(cityPath);
      return response.map((cityList) => CityModel.fromjson(cityList)).toList();
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<AuthUserModel> updateUser(
      {required String city,
      required String birthDate,
      required String height,
      required String clothingSize,
      required String shoeSize}) async {
    try {
      final response = await DioClient.instance.put(update, data: {
        'city': city,
        'birthdate': birthDate,
        'height': height,
        'clothing_size': clothingSize,
        'shoe_size': shoeSize
      });
      return AuthUserModel.fromjson(response['user']);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }
}
