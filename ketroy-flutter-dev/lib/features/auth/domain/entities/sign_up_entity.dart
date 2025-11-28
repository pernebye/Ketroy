import 'package:ketroy_app/features/auth/domain/entities/user_entity.dart';

class SignUpEntity {
  final String message;
  final AuthUserEntity user;

  SignUpEntity({
    required this.message,
    required this.user,
  });
}
