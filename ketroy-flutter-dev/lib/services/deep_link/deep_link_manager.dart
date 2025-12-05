import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:ketroy_app/main.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';
import 'package:ketroy_app/features/discount/presentation/pages/discount_page.dart';
import 'package:ketroy_app/core/transitions/slide_over_page_route.dart';
import 'package:ketroy_app/services/deep_link/create_dynamic_link.dart';

class DeepLinkManager {
  // ✅ Синглтон паттерн
  static final DeepLinkManager _instance = DeepLinkManager._internal();
  factory DeepLinkManager() => _instance;
  DeepLinkManager._internal();

  // ✅ Статический доступ
  static DeepLinkManager get instance => _instance;

  String? receivedLink;
  String? originalLink;
  String? shortUrl;
  String? refParameter;
  
  // ✅ Поддерживаемые домены
  static const List<String> _supportedDomains = [
    'app.ketroy-shop.kz',      // Новый основной домен
    'ketroy-shop.chottu.link', // Старый домен (для обратной совместимости)
  ];
  
  // ✅ Стрим для уведомления о входящих deep links (для навигации)
  final StreamController<String> _deepLinkController =
      StreamController<String>.broadcast();
  
  Stream<String> get deepLinkStream => _deepLinkController.stream;

  // ✅ Стрим для уведомления об изменениях
  final StreamController<String?> _refParameterController =
      StreamController<String?>.broadcast();

  Stream<String?> get refParameterStream => _refParameterController.stream;

  // ✅ Method channel для получения initial link
  static const _channel = MethodChannel('ketroy.app/deep_link');

  void initialize() {
    debugPrint('🔗 Initializing DeepLinkManager...');
    
    // Слушаем deep links через Flutter's native handling
    _setupDeepLinkHandling();
    
    debugPrint('✅ Deep link listener activated for domains: $_supportedDomains');
  }
  
  void _setupDeepLinkHandling() {
    // Получаем initial link (если приложение было запущено через deep link)
    _getInitialLink();
    
    // Примечание: Flutter автоматически обрабатывает deep links через
    // flutter_deeplinking_enabled в AndroidManifest.xml и Associated Domains в iOS.
    // DeepLinkManager получает ссылки через handleLink() вызываемый из main.dart
  }
  
  Future<void> _getInitialLink() async {
    try {
      // Пробуем получить initial link через method channel
      final String? initialLink = await _channel.invokeMethod('getInitialLink');
      if (initialLink != null && initialLink.isNotEmpty) {
        debugPrint('🔗 Got initial link: $initialLink');
        _handleIncomingLink(initialLink);
      }
    } catch (e) {
      // Method channel может быть не настроен - это нормально
      debugPrint('⚠️ Could not get initial link: $e');
    }
  }
  
  /// Проверяет, является ли URL deep link'ом для нашего приложения
  bool _isDeepLink(String url) {
    try {
      final uri = Uri.parse(url);
      return _supportedDomains.contains(uri.host);
    } catch (e) {
      return false;
    }
  }
  
  /// Публичный метод для обработки входящих ссылок (можно вызвать извне)
  void handleLink(String link) {
    _handleIncomingLink(link);
  }

  void _handleIncomingLink(String link) {
    debugPrint('🔗 Received deep link: $link');

    receivedLink = link;

    // Извлекаем ref параметр из URL
    _extractRefParameter(link);

    // Сохраняем ссылку
    if (_isChottuLink(link) || _isKetroyAppLink(link)) {
      shortUrl = link;
      debugPrint('💾 Saved deep link: $shortUrl');
    }

    originalLink = link;

    log(link);
    
    // ✅ ВАЖНО: Выполняем навигацию на основе deep link
    _navigateBasedOnDeepLink(link);
  }
  
  /// Навигация на основе deep link URL
  void _navigateBasedOnDeepLink(String link) {
    try {
      final uri = Uri.parse(link);
      final path = uri.path.toLowerCase();
      
      debugPrint('🧭 Navigating based on deep link path: $path');
      
      // Проверяем различные типы deep links
      if (path.contains('scan-discount') || path.contains('discount')) {
        _navigateToDiscount();
      } else if (path.contains('invite') || uri.queryParameters.containsKey('ref')) {
        // Реферальная ссылка - показываем страницу скидок с применённым рефералом
        _navigateToDiscount();
      } else if (path.contains('gift')) {
        _navigateToGifts();
      } else if (path.contains('profile') || path.contains('bonus')) {
        _navigateToProfile();
      } else {
        // По умолчанию - на главную
        debugPrint('📱 Unknown deep link, staying on current screen');
      }
      
      // Уведомляем слушателей о deep link
      _deepLinkController.add(link);
    } catch (e) {
      debugPrint('❌ Error navigating based on deep link: $e');
    }
  }
  
  void _navigateToDiscount() {
    _safeNavigate(() {
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      
      // Переходим к NavScreen на вкладку профиля
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const NavScreen(initialTab: 1),
        ),
        (route) => false,
      );
      
      // Затем открываем страницу скидок
      Future.delayed(const Duration(milliseconds: 200), () {
        if (navigator.mounted) {
          navigator.push(SlideOverPageRoute(page: const DiscountPage()));
        }
      });
      
      debugPrint('✅ Navigated to discount page via deep link');
    });
  }
  
  void _navigateToGifts() {
    _safeNavigate(() {
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const NavScreen(initialTab: 4),
        ),
        (route) => false,
      );
      
      debugPrint('✅ Navigated to gifts page via deep link');
    });
  }
  
  void _navigateToProfile() {
    _safeNavigate(() {
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const NavScreen(initialTab: 1),
        ),
        (route) => false,
      );
      
      debugPrint('✅ Navigated to profile via deep link');
    });
  }
  
  void _safeNavigate(VoidCallback navigationCallback) {
    try {
      if (navigatorKey.currentState != null) {
        navigationCallback();
      } else {
        debugPrint('⚠️ Navigator not available for deep link navigation');
      }
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
    }
  }

  String _extractRefParameter(String link) {
    try {
      final uri = Uri.parse(link);
      final ref = uri.queryParameters['ref'];

      if (ref != null && ref.isNotEmpty) {
        refParameter = ref;
        debugPrint('💎 Extracted ref parameter: $refParameter');

        // ✅ Уведомляем слушателей об изменении
        _refParameterController.add(refParameter);

        return refParameter ?? '';
      }
    } catch (e) {
      debugPrint('❌ Error extracting ref parameter: $e');
    }
    return '';
  }

  // ✅ Геттеры для доступа к данным
  String? get currentRefParameter => refParameter;
  String? get currentReceivedLink => receivedLink;
  String? get currentOriginalLink => originalLink;
  String? get currentShortUrl => shortUrl;

  // ✅ Метод для очистки данных
  void clearLinkData() {
    receivedLink = null;
    originalLink = null;
    shortUrl = null;
    refParameter = null;
    _refParameterController.add(null);
  }

  // ✅ Проверка наличия ref параметра
  bool get hasRefParameter => refParameter != null && refParameter!.isNotEmpty;

  /// Проверяет, является ли ссылка от ChottuLink (для обратной совместимости)
  bool _isChottuLink(String link) {
    return link.contains('chottu.link') && !link.contains('apps.apple.com');
  }
  
  /// Проверяет, является ли ссылка от Ketroy (новый домен)
  bool _isKetroyAppLink(String link) {
    return link.contains(DeepLinkConstants.domain);
  }

  /// Проверяет, является ли ссылка на App Store
  bool _isAppStoreLink(String link) {
    return link.contains('apps.apple.com');
  }
  
  /// Проверяет, является ли ссылка на Play Store
  bool _isPlayStoreLink(String link) {
    return link.contains('play.google.com');
  }
  
  /// Проверяет, является ли ссылка ссылкой на магазин приложений
  bool _isStoreLink(String link) {
    return _isAppStoreLink(link) || _isPlayStoreLink(link);
  }

  void dispose() {
    _refParameterController.close();
    _deepLinkController.close();
  }
}
