import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/auth/data/models/verify_code_response_model.dart';
import 'package:ketroy_app/features/auth/domain/repository/auth_repository.dart';

/// Use case для отправки кода верификации (регистрация)
class SendVerifyCode
    implements UseCase<VerifyCodeResponseModel, SendVerifyCodeParams> {
  final AuthRepository authRepository;
  SendVerifyCode(this.authRepository);
  @override
  Future<Either<Failure, VerifyCodeResponseModel>> call(
      SendVerifyCodeParams params, String? path) async {
    return await authRepository.sendVerifyCode(
        phone: params.phone, countryCode: params.countryCode);
  }
}

/// Use case для отправки кода верификации (вход)
class LoginSendCode
    implements UseCase<VerifyCodeResponseModel, SendVerifyCodeParams> {
  final AuthRepository authRepository;
  LoginSendCode(this.authRepository);
  @override
  Future<Either<Failure, VerifyCodeResponseModel>> call(
      SendVerifyCodeParams params, String? path) async {
    return await authRepository.loginSendCode(
        phone: params.phone, countryCode: params.countryCode);
  }
}

class SendVerifyCodeParams {
  final String phone;
  final String countryCode;

  SendVerifyCodeParams({required this.phone, required this.countryCode});
}
