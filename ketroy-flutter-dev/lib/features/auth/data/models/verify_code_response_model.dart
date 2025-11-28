/// Модель ответа на отправку кода верификации
/// Содержит информацию о существовании пользователя
class VerifyCodeResponseModel {
  final String message;
  final bool userExists;

  const VerifyCodeResponseModel({
    required this.message,
    required this.userExists,
  });

  factory VerifyCodeResponseModel.fromJson(Map<String, dynamic> json) {
    return VerifyCodeResponseModel(
      message: json['message'] ?? '',
      userExists: json['user_exists'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'user_exists': userExists,
    };
  }
}





