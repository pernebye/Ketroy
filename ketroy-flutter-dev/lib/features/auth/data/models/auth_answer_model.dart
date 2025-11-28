import 'package:ketroy_app/features/auth/data/models/user_model.dart';
import 'package:ketroy_app/features/auth/domain/entities/auth_answer.dart';

class AuthAnswerModel extends AuthAnswer {
  final bool isNewUser;

  AuthAnswerModel({
    required super.token,
    required super.user,
    required super.message,
    this.isNewUser = false,
  });

  factory AuthAnswerModel.fromJson(Map<String, dynamic> map) {
    return AuthAnswerModel(
      token: map['token'] ?? '',
      user: map.containsKey('user') && map['user'] != null
          ? AuthUserModel.fromjson(map['user'])
          : null,
      message: map['message'] ?? '',
      isNewUser: map['is_new_user'] ?? false,
    );
  }

  AuthAnswerModel copyWith({
    String? token,
    AuthUserModel? user,
    String? message,
    bool? isNewUser,
  }) {
    return AuthAnswerModel(
      token: token ?? this.token,
      user: user ?? this.user,
      message: message ?? this.message,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }
}
