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

  /// Get the language name for AI backend (used in prompts)
  /// Maps language code to full language name that backend expects
  /// Using English names as backend likely validates against these
  String get aiLanguageName {
    switch (this) {
      case AppLanguage.system:
        return 'russian'; // Default fallback
      case AppLanguage.russian:
        return 'russian';
      case AppLanguage.kazakh:
        return 'kazakh';
      case AppLanguage.english:
        return 'english';
      case AppLanguage.turkish:
        return 'turkish';
    }
  }

  /// Static method to get AI language name from code
  /// Using English names as backend likely validates against these
  static String getAILanguageNameFromCode(String code) {
    switch (code) {
      case 'ru':
        return 'russian';
      case 'kk':
        return 'kazakh';
      case 'en':
        return 'english';
      case 'tr':
        return 'turkish';
      default:
        return 'russian';
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
      
      debugPrint('🌍 LocalizationService.initialize: savedCode from prefs = "$savedCode"');
      
      if (savedCode != null) {
        _currentLanguage = AppLanguageExtension.fromCode(savedCode);
        _locale = _currentLanguage.locale;
        debugPrint('🌍 LocalizationService.initialize: Loaded language: $_currentLanguage, locale: $_locale');
      } else {
        _currentLanguage = AppLanguage.system;
        _locale = null;
        debugPrint('🌍 LocalizationService.initialize: No saved language, using system');
      }
      
      // Log device locale for debugging
      final deviceLocale = PlatformDispatcher.instance.locale;
      debugPrint('🌍 LocalizationService.initialize: Device locale: $deviceLocale');
      
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

  /// Get language code for AI responses
  /// This method properly handles:
  /// - Explicit language selection (returns the selected language code)
  /// - System language mode (returns system language if supported, otherwise Russian)
  /// - Unsupported languages (Uzbek, Kyrgyz, etc.) default to Russian
  /// 
  /// Supported AI languages: en, ru, kk, tr
  String getLanguageCodeForAI() {
    debugPrint('🌍 LocalizationService.getLanguageCodeForAI: _currentLanguage=$_currentLanguage, _locale=$_locale, _isInitialized=$_isInitialized');
    
    // If user has explicitly selected a language (not system)
    if (_currentLanguage != AppLanguage.system) {
      final code = _currentLanguage.code;
      debugPrint('🌍 LocalizationService: Using explicit language: $code (from $_currentLanguage)');
      return code;
    }

    // System language mode - get device locale
    final deviceLocale = PlatformDispatcher.instance.locale;
    final deviceLanguageCode = deviceLocale.languageCode;
    debugPrint('🌍 LocalizationService: System mode, device locale: $deviceLocale, languageCode: $deviceLanguageCode');

    // List of languages supported by AI
    const supportedAiLanguages = ['en', 'ru', 'kk', 'tr'];

    // Check if device language is supported by AI
    if (supportedAiLanguages.contains(deviceLanguageCode)) {
      debugPrint('🌍 LocalizationService: Device language supported, returning: $deviceLanguageCode');
      return deviceLanguageCode;
    }

    // For unsupported languages (Uzbek, Kyrgyz, etc.) default to Russian
    debugPrint('🌍 LocalizationService: Device language NOT supported ($deviceLanguageCode), defaulting to: ru');
    return 'ru';
  }

  /// Static helper to get language code for AI from context
  /// Uses Localizations.localeOf which properly resolves the app's current locale
  static String getAILanguageFromContext(BuildContext context) {
    // Get the resolved locale from Flutter's localization system
    // This properly reflects both explicit language choice and system language
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    
    debugPrint('🌍 LocalizationService.getAILanguageFromContext: Resolved locale: $locale, languageCode: $languageCode');
    
    // List of languages supported by AI
    const supportedAiLanguages = ['en', 'ru', 'kk', 'tr'];
    
    // Check if the resolved language is supported by AI
    if (supportedAiLanguages.contains(languageCode)) {
      debugPrint('🌍 LocalizationService.getAILanguageFromContext: Returning supported language: $languageCode');
      return languageCode;
    }
    
    // For unsupported languages default to Russian
    debugPrint('🌍 LocalizationService.getAILanguageFromContext: Language $languageCode not supported, defaulting to ru');
    return 'ru';
  }
}

