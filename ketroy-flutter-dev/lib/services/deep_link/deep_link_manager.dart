import 'dart:async';
import 'dart:developer';

import 'package:chottu_link/chottu_link.dart';
import 'package:flutter/material.dart';
import 'package:ketroy_app/main.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';
import 'package:ketroy_app/features/discount/presentation/pages/discount_page.dart';
import 'package:ketroy_app/core/transitions/slide_over_page_route.dart';

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
  StreamSubscription<String>? _linkSubscription;
  
  // ✅ Стрим для уведомления о входящих deep links (для навигации)
  final StreamController<String> _deepLinkController =
      StreamController<String>.broadcast();
  
  Stream<String> get deepLinkStream => _deepLinkController.stream;

  // ✅ Стрим для уведомления об изменениях
  final StreamController<String?> _refParameterController =
      StreamController<String?>.broadcast();

  Stream<String?> get refParameterStream => _refParameterController.stream;

  void initialize() {
    if (!ChottuLink.isInitialized()) {
      debugPrint('❌ ChottuLink не инициализован');
      return;
    }

    _linkSubscription = ChottuLink.onLinkReceived.listen(
      _handleIncomingLink,
      onError: _handleLinkError,
    );

    debugPrint('✅ Deep link listener activated');
  }

  void _handleIncomingLink(String link) {
    debugPrint('🔗 Received deep link: $link');

    receivedLink = link;

    // Извлекаем ref параметр из URL
    _extractRefParameter(link);

    if (_isChottuLink(link)) {
      shortUrl = link;
      debugPrint('💾 Saved short link: $shortUrl');
    }

    if (_isAppStoreLink(link)) {
      _resolveOriginalLink(link);
    } else {
      originalLink = link;
    }

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

  void _handleLinkError(dynamic error) {
    debugPrint('❌ Link reception error: $error');
    receivedLink = 'Error: $error';
  }

  void _resolveOriginalLink(String fallbackUrl) {
    debugPrint('🔍 Attempting to resolve original link for: $fallbackUrl');

    if (shortUrl != null) {
      _getAppLinkDataFromUrl(shortUrl!);
    }
  }

  void _getAppLinkDataFromUrl(String shortUrl) {
    debugPrint('🔗 Getting data for short link: $shortUrl');

    ChottuLink.getAppLinkDataFromUrl(
      shortUrl: shortUrl,
      onSuccess: (resolvedLink) {
        debugPrint(
            '✅ Successfully retrieved original link: ${resolvedLink.link}');
        debugPrint('✅ Short link: ${resolvedLink.shortLink}');
        originalLink = resolvedLink.link ?? resolvedLink.shortLink;
      },
      onError: (error) {
        debugPrint('❌ Error retrieving original link: ${error.message}');
        originalLink = 'Retrieval error: ${error.message}';
      },
    );
  }

  bool _isChottuLink(String link) {
    return link.contains('chottu.link') && !link.contains('apps.apple.com');
  }

  bool _isAppStoreLink(String link) {
    return link.contains('apps.apple.com');
  }

  void dispose() {
    _linkSubscription?.cancel();
    _refParameterController.close();
    _deepLinkController.close();
  }
}
