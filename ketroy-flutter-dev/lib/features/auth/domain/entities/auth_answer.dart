import 'package:ketroy_app/features/auth/domain/entities/user_entity.dart';

class AuthAnswer {
  final String token;
  final AuthUserEntity? user;
  final String message;

  AuthAnswer({required this.token, required this.user, required this.message});
}
