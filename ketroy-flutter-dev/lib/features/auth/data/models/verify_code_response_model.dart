import 'package:flutter/foundation.dart';

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
    debugPrint('🔍 Parsing VerifyCodeResponseModel: $json');
    
    // Извлекаем message - может быть в разных форматах
    String message = '';
    if (json.containsKey('message')) {
      final msgValue = json['message'];
      if (msgValue is String) {
        message = msgValue;
      } else if (msgValue != null) {
        message = msgValue.toString();
      }
    }
    
    // Извлекаем user_exists - может быть bool, int, string
    bool userExists = false;
    if (json.containsKey('user_exists')) {
      final existsValue = json['user_exists'];
      if (existsValue is bool) {
        userExists = existsValue;
      } else if (existsValue is int) {
        userExists = existsValue == 1;
      } else if (existsValue is String) {
        userExists = existsValue.toLowerCase() == 'true' || existsValue == '1';
      }
    }
    
    debugPrint('✅ Parsed: message="$message", userExists=$userExists');
    
    return VerifyCodeResponseModel(
      message: message,
      userExists: userExists,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'user_exists': userExists,
    };
  }
  
  @override
  String toString() => 'VerifyCodeResponseModel(message: $message, userExists: $userExists)';
}
