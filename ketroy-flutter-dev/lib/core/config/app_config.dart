/// ============================================
/// KETROY APP - CONFIGURATION
/// ============================================
/// Переключение между dev и prod окружениями
///
/// Для переключения измените [Environment.current]
library app_config;

import 'package:flutter/foundation.dart';

enum Environment {
  development,
  production,
}

class AppConfig {
  // ============================================
  // ТЕКУЩЕЕ ОКРУЖЕНИЕ
  // ============================================
  // ⚠️ PRODUCTION MODE - для релиза в App Store / Google Play
  static const Environment current = Environment.production;

  // ============================================
  // API ENDPOINTS
  // ============================================
  static String get baseUrl {
    switch (current) {
      case Environment.development:
        // Для эмулятора Android используйте 10.0.2.2 вместо localhost
        // Для iOS симулятора используйте localhost или 127.0.0.1
        // Для реального устройства используйте IP вашего компьютера
        return 'http://10.0.2.2:8000/api'; // Android Emulator
      // return 'http://localhost:8000/api'; // iOS Simulator
      // return 'http://192.168.1.100:8000/api'; // Real device (your PC IP)
      case Environment.production:
        return 'https://api.ketroy.kz/api';
    }
  }

  // ============================================
  // FEATURE FLAGS
  // ============================================
  static bool get isDebugMode => current == Environment.development;
  static bool get enableLogging => current == Environment.development;
  static bool get useMockSms => current == Environment.development;

  // ============================================
  // TIMEOUTS
  // ============================================
  static Duration get connectTimeout {
    switch (current) {
      case Environment.development:
        return const Duration(seconds: 60); // Увеличено для dev
      case Environment.production:
        return const Duration(seconds: 15);
    }
  }

  static Duration get receiveTimeout {
    switch (current) {
      case Environment.development:
        return const Duration(seconds: 60); // Увеличено для больших ответов
      case Environment.production:
        return const Duration(seconds: 30);
    }
  }

  // ============================================
  // EXTERNAL SERVICES
  // ============================================
  static String get chottuLinkApiKey {
    switch (current) {
      case Environment.development:
        return 'dev_api_key';
      case Environment.production:
        return 'prod_api_key'; // Замените на реальный ключ
    }
  }

  // ============================================
  // STORAGE KEYS
  // ============================================
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String onboardingKey = 'onboarding_complete';

  // ============================================
  // HELPERS
  // ============================================
  static String get environmentName {
    switch (current) {
      case Environment.development:
        return 'Development';
      case Environment.production:
        return 'Production';
    }
  }

  static void printConfig() {
    if (enableLogging) {
      debugPrint('╔══════════════════════════════════════╗');
      debugPrint('║       KETROY APP CONFIGURATION       ║');
      debugPrint('╠══════════════════════════════════════╣');
      debugPrint('║ Environment: $environmentName');
      debugPrint('║ Base URL: $baseUrl');
      debugPrint('║ Debug Mode: $isDebugMode');
      debugPrint('║ Connect Timeout: ${connectTimeout.inSeconds}s');
      debugPrint('╚══════════════════════════════════════╝');
    }
  }
}
