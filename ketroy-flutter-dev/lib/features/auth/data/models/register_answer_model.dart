import 'package:ketroy_app/features/auth/data/models/register_user_model.dart';
import 'package:ketroy_app/features/auth/domain/entities/register_answer.dart';

class RegisterAnswerModel extends RegisterAnswer {
  RegisterAnswerModel(
      {required super.token, required super.user, required super.message});

  factory RegisterAnswerModel.fromjson(Map<String, dynamic> json) {
    return RegisterAnswerModel(
        token: json['token'],
        user: json.containsKey('user') && json['user'] != null
            ? RegisterUserModel.fromjson(json['user'])
            : null,
        message: json['message']);
  }
}
