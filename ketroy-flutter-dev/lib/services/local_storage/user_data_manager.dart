import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ketroy_app/features/auth/domain/entities/promo_code_entity.dart';
import 'package:ketroy_app/features/auth/domain/entities/register_answer.dart';
import 'package:ketroy_app/features/auth/domain/entities/register_user_entity.dart';
import 'package:ketroy_app/features/auth/domain/entities/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDataManager {
  /// Глобальный notifier для отслеживания изменений состояния авторизации.
  /// Значение увеличивается при каждом изменении (login/logout).
  /// Используйте ValueListenableBuilder для автоматического обновления UI.
  static final ValueNotifier<int> authStateNotifier = ValueNotifier<int>(0);

  /// Уведомить все слушатели об изменении состояния авторизации
  static void _notifyAuthStateChanged() {
    authStateNotifier.value++;
  }

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Ключи для хранения
  static const String _tokenKey = 'user_token';
  static const String _qrTokenKey = 'qr_token';
  static const String _qrTokenTimestampKey = 'qr_token_timestamp';
  static const String _userDataKey = 'user_data';
  static const String _messageKey = 'server_message';
  static const String _promoCodeKey = 'promo_code';
  
  // Время жизни QR токена (10 минут)
  static const Duration _qrTokenLifetime = Duration(minutes: 10);

  /// Сохранить токен в secure storage
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    _notifyAuthStateChanged(); // Уведомляем о смене состояния авторизации
  }

  /// Получить токен из secure storage
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Сохранить QR токен в secure storage с меткой времени
  static Future<void> saveQrToken(String qrToken) async {
    // Сначала сохраняем timestamp, потом токен
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_qrTokenTimestampKey, DateTime.now().millisecondsSinceEpoch);
    await _secureStorage.write(key: _qrTokenKey, value: qrToken);
    debugPrint('✅ QR token saved with timestamp');
  }

  /// Получить QR токен из secure storage (без проверки таймера)
  static Future<String?> getQrToken() async {
    return await _secureStorage.read(key: _qrTokenKey);
  }
  
  /// Получить QR токен только если он действителен (не истёк)
  /// ⚠️ ВАЖНО: Этот метод очищает токен если он невалиден!
  /// Для проверки без очистки используйте isQrTokenValid() + getQrToken()
  static Future<String?> getValidQrToken() async {
    // Сначала читаем токен
    final token = await _secureStorage.read(key: _qrTokenKey);
    if (token == null || token.isEmpty) {
      debugPrint('🔍 getValidQrToken: no token found');
      return null;
    }
    
    // Проверяем валидность
    if (!await isQrTokenValid()) {
      debugPrint('🔍 getValidQrToken: token invalid, clearing');
      await clearQrToken();
      return null;
    }
    
    debugPrint('🔍 getValidQrToken: returning valid token');
    return token;
  }
  
  /// Проверить, действителен ли QR токен (не прошло ли 10 минут)
  static Future<bool> isQrTokenValid() async {
    try {
      // Сначала проверяем есть ли сам токен
      final token = await _secureStorage.read(key: _qrTokenKey);
      if (token == null || token.isEmpty) {
        debugPrint('🔐 QR token validity: no token');
        return false;
      }
      
      final prefs = await SharedPreferences.getInstance();
      // ✅ Перезагружаем prefs чтобы получить актуальные данные
      await prefs.reload();
      final timestamp = prefs.getInt(_qrTokenTimestampKey);
      
      if (timestamp == null) {
        // Токен есть, но нет timestamp - считаем валидным (для обратной совместимости)
        // Но сразу устанавливаем timestamp
        debugPrint('🔐 QR token validity: no timestamp, setting now');
        await prefs.setInt(_qrTokenTimestampKey, DateTime.now().millisecondsSinceEpoch);
        return true;
      }
      
      final scanTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(scanTime);
      
      final isValid = difference < _qrTokenLifetime;
      debugPrint('🔐 QR token validity check: $isValid (${difference.inSeconds}s elapsed, expires in ${(_qrTokenLifetime - difference).inSeconds}s)');
      
      return isValid;
    } catch (e) {
      debugPrint('❌ Error checking QR token validity: $e');
      // При ошибке считаем токен валидным чтобы не сбрасывать скидку
      return true;
    }
  }
  
  /// Получить оставшееся время действия QR токена
  static Future<Duration?> getQrTokenRemainingTime() async {
    try {
      // Сначала проверяем есть ли токен
      final token = await _secureStorage.read(key: _qrTokenKey);
      if (token == null || token.isEmpty) {
        return null;
      }
      
      final prefs = await SharedPreferences.getInstance();
      // ✅ Перезагружаем prefs чтобы получить актуальные данные
      await prefs.reload();
      final timestamp = prefs.getInt(_qrTokenTimestampKey);
      
      if (timestamp == null) {
        return _qrTokenLifetime; // Если нет timestamp, возвращаем полное время
      }
      
      final scanTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final expiryTime = scanTime.add(_qrTokenLifetime);
      final now = DateTime.now();
      
      if (now.isAfter(expiryTime)) {
        return null;
      }
      
      return expiryTime.difference(now);
    } catch (e) {
      debugPrint('❌ Error getting QR token remaining time: $e');
      return _qrTokenLifetime; // При ошибке возвращаем полное время
    }
  }
  
  /// Очистить QR токен
  static Future<void> clearQrToken() async {
    await _secureStorage.delete(key: _qrTokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_qrTokenTimestampKey);
    debugPrint('🗑️ QR token cleared');
  }

  /// Сохранить объект пользователя
  static Future<void> saveUser(AuthUserEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    // Сериализуем объект в JSON для хранения
    final userJson = jsonEncode(_userToMap(user));
    await prefs.setString(_userDataKey, userJson);
  }

  /// Сохранить промокод
  static Future<void> savePromoCode(String promoCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_promoCodeKey, promoCode);
  }

  /// Получить промокод
  static Future<String?> getPromoCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_promoCodeKey);
  }

  /// Очистить сохраненный промокод
  static Future<void> clearPromoCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_promoCodeKey);
    debugPrint('🗑️ Cleared saved promo code');
  }

  /// Сохранить объект пользователя (RegisterUserEntity)
  static Future<void> saveRegisterUser(RegisterUserEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(_registerUserToMap(user));
    await prefs.setString(_userDataKey, userJson);
  }

  /// Получить объект пользователя
  static Future<AuthUserEntity?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userDataKey);

    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return _mapToUser(userMap);
    }

    return null;
  }

  /// Получить объект пользователя как RegisterUserEntity
  static Future<RegisterUserEntity?> getRegisterUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userDataKey);

    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return _mapToRegisterUser(userMap);
    }

    return null;
  }

  /// Сохранить сообщение с сервера
  static Future<void> saveMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_messageKey, message);
  }

  /// Получить сообщение с сервера
  static Future<String?> getMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_messageKey);
  }

  /// Сохранить все данные из ответа сервера
  static Future<void> saveServerResponse(
      String token, AuthUserEntity user, String? message) async {
    await saveToken(token);
    await saveUser(user);
    if (message != null) {
      await saveMessage(message);
    }
  }

  /// Сохранить RegisterAnswer полностью
  static Future<void> saveRegisterAnswer(RegisterAnswer registerAnswer) async {
    await saveToken(registerAnswer.token);
    if (registerAnswer.user != null) {
      await saveRegisterUser(registerAnswer.user!);
    }
    await saveMessage(registerAnswer.message);
  }

  /// Преобразовать RegisterUserEntity в AuthUserEntity и сохранить
  static Future<void> convertRegisterToAuthUser() async {
    final registerUser = await getRegisterUser();
    if (registerUser != null) {
      final authUser = AuthUserEntity(
        id: registerUser.id,
        name: registerUser.name,
        phone: registerUser.phone,
        avatarImage: null, // RegisterUserEntity не имеет avatarImage
        countryCode: registerUser.countryCode,
        city: registerUser.city,
        birthdate: registerUser.birthdate,
        height: registerUser.height,
        clothingSize: registerUser.clothingSize,
        shoeSize: registerUser.shoeSize,
        verificationCode: '', // Устанавливаем пустое значение
        codeExpires: null,
        createdAt: registerUser.createdAt,
        updatedAt: registerUser.updatedAt,
        deviceToken: registerUser.deviceToken,
        surname: registerUser.surname,
        discount: registerUser.discount,
        userPromoCode: registerUser.usedPromoCode ? 1 : 0,
        referrerId: null,
        bonusAmount: registerUser.bonusAmount,
        promoCode: null,
      );

      // Сохраняем как AuthUserEntity
      await saveUser(authUser);

      // Удаляем старые данные RegisterUserEntity (опционально)
      // await _clearRegisterUserData();
    }
  }

  /// Сохранить RegisterAnswer и сразу преобразовать в AuthUser
  static Future<void> saveRegisterAnswerAndConvert(
      RegisterAnswer registerAnswer) async {
    await saveToken(registerAnswer.token);
    if (registerAnswer.user != null) {
      await saveRegisterUser(registerAnswer.user!);
      // Сразу преобразуем в AuthUser
      await convertRegisterToAuthUser();
    }
    await saveMessage(registerAnswer.message);
  }

  /// Проверить авторизован ли пользователь
  static Future<bool> isUserLoggedIn() async {
    final token = await getToken();
    final authUser = await getUser();
    final registerUser = await getRegisterUser();
    return token != null && (authUser != null || registerUser != null);
  }

  /// Очистить все данные пользователя
  static Future<void> clearUserData() async {
    await _secureStorage.delete(key: _tokenKey);
    await clearQrToken(); // Очищаем QR токен при выходе

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
    await prefs.remove(_messageKey);
    _notifyAuthStateChanged(); // Уведомляем о смене состояния авторизации
  }

  /// Проверить истек ли код верификации
  static Future<bool> isVerificationCodeExpired() async {
    final user = await getUser();
    if (user?.codeExpires != null) {
      return DateTime.now().isAfter(user!.codeExpires!);
    }
    return true;
  }

  /// Обновить пользователя
  static Future<void> updateUser(AuthUserEntity user) async {
    await saveUser(user);
  }

  // Приватные методы для сериализации AuthUserEntity
  static Map<String, dynamic> _userToMap(AuthUserEntity user) {
    return {
      'type': 'auth', // Добавляем тип для различения
      'id': user.id,
      'name': user.name,
      'phone': user.phone,
      'avatarImage': user.avatarImage,
      'countryCode': user.countryCode,
      'city': user.city,
      'birthdate': user.birthdate,
      'height': user.height,
      'clothingSize': user.clothingSize,
      'shoeSize': user.shoeSize,
      'verificationCode': user.verificationCode,
      'codeExpires': user.codeExpires?.toIso8601String(),
      'createdAt': user.createdAt?.toIso8601String(),
      'updatedAt': user.updatedAt?.toIso8601String(),
      'deviceToken': user.deviceToken,
      'surname': user.surname,
      'discount': user.discount,
      'userPromoCode': user.userPromoCode,
      'referrerId': user.referrerId,
      'bonusAmount': user.bonusAmount,
      'promoCode': user.promoCode != null
          ? {
              'id': user.promoCode!.id,
              'code': user.promoCode!.code,
              'userId': user.promoCode!.userId,
              'createdAt': user.promoCode!.createdAt?.toIso8601String(),
              'updatedAt': user.promoCode!.updatedAt?.toIso8601String(),
            }
          : null,
    };
  }

  // Приватные методы для сериализации RegisterUserEntity
  static Map<String, dynamic> _registerUserToMap(RegisterUserEntity user) {
    return {
      'type': 'register', // Добавляем тип для различения
      'id': user.id,
      'name': user.name,
      'surname': user.surname,
      'phone': user.phone,
      'countryCode': user.countryCode,
      'city': user.city,
      'birthdate': user.birthdate,
      'height': user.height,
      'clothingSize': user.clothingSize,
      'shoeSize': user.shoeSize,
      'createdAt': user.createdAt?.toIso8601String(),
      'updatedAt': user.updatedAt?.toIso8601String(),
      'deviceToken': user.deviceToken,
      'discount': user.discount,
      'usedPromoCode': user.usedPromoCode,
      'bonusAmount': user.bonusAmount,
    };
  }

  static AuthUserEntity _mapToUser(Map<String, dynamic> map) {
    PromoCodeEntity? promoCode;
    if (map['promoCode'] != null) {
      final promoMap = map['promoCode'] as Map<String, dynamic>;
      promoCode = PromoCodeEntity(
        id: promoMap['id'],
        code: promoMap['code'],
        userId: promoMap['userId'],
        createdAt: promoMap['createdAt'] != null
            ? DateTime.parse(promoMap['createdAt'])
            : null,
        updatedAt: promoMap['updatedAt'] != null
            ? DateTime.parse(promoMap['updatedAt'])
            : null,
      );
    }

    return AuthUserEntity(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      avatarImage: map['avatarImage'],
      countryCode: map['countryCode'],
      city: map['city'],
      birthdate: map['birthdate'],
      height: map['height'],
      clothingSize: map['clothingSize'],
      shoeSize: map['shoeSize'],
      verificationCode: map['verificationCode'] ?? '',
      codeExpires: map['codeExpires'] != null
          ? DateTime.parse(map['codeExpires'])
          : null,
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      deviceToken: map['deviceToken'],
      surname: map['surname'] ?? '',
      discount: map['discount'],
      userPromoCode: map['userPromoCode'],
      referrerId: map['referrerId'],
      bonusAmount: map['bonusAmount'],
      promoCode: promoCode,
    );
  }

  static RegisterUserEntity _mapToRegisterUser(Map<String, dynamic> map) {
    return RegisterUserEntity(
      id: map['id'],
      name: map['name'],
      surname: map['surname'],
      phone: map['phone'],
      countryCode: map['countryCode'],
      city: map['city'],
      birthdate: map['birthdate'],
      height: map['height'],
      clothingSize: map['clothingSize'],
      shoeSize: map['shoeSize'],
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      deviceToken: map['deviceToken'],
      discount: map['discount'],
      usedPromoCode: map['usedPromoCode'] ?? false,
      bonusAmount: map['bonusAmount'],
    );
  }
}
