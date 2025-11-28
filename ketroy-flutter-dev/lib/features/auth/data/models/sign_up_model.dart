import 'package:ketroy_app/features/auth/data/models/user_model.dart';
import 'package:ketroy_app/features/auth/domain/entities/sign_up_entity.dart';

class SignUpModel extends SignUpEntity {
  SignUpModel({required super.message, required super.user});

  factory SignUpModel.fromjson(Map<String, dynamic> json) => SignUpModel(
      message: json['message'], user: AuthUserModel.fromjson(json['user']));
}
