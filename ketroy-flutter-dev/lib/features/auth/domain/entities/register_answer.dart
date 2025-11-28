import 'package:ketroy_app/features/auth/domain/entities/register_user_entity.dart';

class RegisterAnswer {
  final String token;
  final RegisterUserEntity? user;
  final String message;

  RegisterAnswer(
      {required this.token, required this.user, required this.message});
}
