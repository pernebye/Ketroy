import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported languages in the app
enum AppLanguage {
  system, // Use device language
  russian,
  kazakh,
  english,
  turkish,
}

/// Extension to get locale from AppLanguage
extension AppLanguageExtension on AppLanguage {
  Locale? get locale {
    switch (this) {
      case AppLanguage.system:
        return null; // Will use system locale
      case AppLanguage.russian:
        return const Locale('ru');
      case AppLanguage.kazakh:
        return const Locale('kk');
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.turkish:
        return const Locale('tr');
    }
  }

  String get code {
    switch (this) {
      case AppLanguage.system:
        return 'system';
      case AppLanguage.russian:
        return 'ru';
      case AppLanguage.kazakh:
        return 'kk';
      case AppLanguage.english:
        return 'en';
      case AppLanguage.turkish:
        return 'tr';
    }
  }

  String get nativeName {
    switch (this) {
      case AppLanguage.system:
        return 'System'; // Will be translated
      case AppLanguage.russian:
        return 'Русский';
      case AppLanguage.kazakh:
        return 'Қазақша';
      case AppLanguage.english:
        return 'English';
      case AppLanguage.turkish:
        return 'Türkçe';
    }
  }

  String get flagAsset {
    switch (this) {
      case AppLanguage.system:
        return 'images/system.png';
      case AppLanguage.russian:
        return 'images/rus.png';
      case AppLanguage.kazakh:
        return 'images/kz.png';
      case AppLanguage.english:
        return 'images/eng.png';
      case AppLanguage.turkish:
        return 'images/tur.png';
    }
  }

  static AppLanguage fromCode(String code) {
    switch (code) {
      case 'ru':
        return AppLanguage.russian;
      case 'kk':
        return AppLanguage.kazakh;
      case 'en':
        return AppLanguage.english;
      case 'tr':
        return AppLanguage.turkish;
      default:
        return AppLanguage.system;
    }
  }
}

/// Service to manage app localization
class LocalizationService extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const List<Locale> supportedLocales = [
    Locale('ru'),
    Locale('kk'),
    Locale('en'),
    Locale('tr'),
  ];

  AppLanguage _currentLanguage = AppLanguage.system;
  Locale? _locale;
  bool _isInitialized = false;

  AppLanguage get currentLanguage => _currentLanguage;
  Locale? get locale => _locale;
  bool get isInitialized => _isInitialized;

  /// Get the effective locale (considering system setting)
  Locale get effectiveLocale {
    if (_currentLanguage == AppLanguage.system) {
      // Get device locale
      final deviceLocale = PlatformDispatcher.instance.locale;
      // Check if device locale is supported
      final supportedLanguageCodes = supportedLocales.map((l) => l.languageCode).toList();
      if (supportedLanguageCodes.contains(deviceLocale.languageCode)) {
        return Locale(deviceLocale.languageCode);
      }
      // Default to Russian if device locale is not supported
      return const Locale('ru');
    }
    return _locale ?? const Locale('ru');
  }

  /// Initialize the service and load saved language preference
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_languageKey);
      
      if (savedCode != null) {
        _currentLanguage = AppLanguageExtension.fromCode(savedCode);
        _locale = _currentLanguage.locale;
      } else {
        _currentLanguage = AppLanguage.system;
        _locale = null;
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing LocalizationService: $e');
      _currentLanguage = AppLanguage.system;
      _locale = null;
      _isInitialized = true;
    }
  }

  /// Set the app language
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.code);
      
      _currentLanguage = language;
      _locale = language.locale;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  /// Check if using system language
  bool get isUsingSystemLanguage => _currentLanguage == AppLanguage.system;

  /// Get display name for current language setting
  String getCurrentLanguageDisplayName() {
    if (_currentLanguage == AppLanguage.system) {
      return effectiveLocale.languageCode;
    }
    return _currentLanguage.nativeName;
  }

  /// Locale resolution callback for MaterialApp
  static Locale? localeResolutionCallback(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
    if (locale == null) return supportedLocales.first;
    
    // Check if the current device locale is supported
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }
    
    // Default to Russian
    return const Locale('ru');
  }

  /// Get all available languages for selection
  static List<AppLanguage> get availableLanguages => [
    AppLanguage.system,
    AppLanguage.russian,
    AppLanguage.kazakh,
    AppLanguage.english,
    AppLanguage.turkish,
  ];
}

