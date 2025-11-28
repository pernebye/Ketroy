import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/auth/domain/entities/auth_answer.dart';
import 'package:ketroy_app/features/auth/domain/repository/auth_repository.dart';

class SmsAuth implements UseCase<AuthAnswer, SmsAuthParams> {
  final AuthRepository authRepository;
  SmsAuth(this.authRepository);
  @override
  Future<Either<Failure, AuthAnswer>> call(
      SmsAuthParams params, String? path) async {
    return await authRepository.loginWithSms(
        code: params.code, phone: params.phone, sms: params.sms);
  }
}

class SmsAuthParams {
  final String code;
  final String phone;
  final String sms;

  SmsAuthParams({required this.code, required this.phone, required this.sms});
}
