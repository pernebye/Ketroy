import 'dart:async';
import 'dart:developer';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:ketroy_app/main.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';
import 'package:ketroy_app/features/discount/presentation/pages/discount_page.dart';
import 'package:ketroy_app/core/transitions/slide_over_page_route.dart';
import 'package:ketroy_app/services/deep_link/create_dynamic_link.dart';
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';
import 'package:ketroy_app/core/common/widgets/promo_code_success_dialog.dart';
import 'package:ketroy_app/core/common/widgets/top_toast.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:ketroy_app/features/discount/domain/repository/discount_repository.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

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

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  
  void initialize() {
    debugPrint('🔗 Initializing DeepLinkManager...');
    
    _appLinks = AppLinks();
    
    // ✅ Настраиваем обработку Universal Links / Deep Links
    _setupAppLinks();
    
    debugPrint('✅ Deep link listener activated for domains: $_supportedDomains');
  }
  
  void _setupAppLinks() async {
    try {
      // 1. Получаем initial link (если приложение было запущено через deep link)
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('🔗 Initial deep link: $initialLink');
        _handleIncomingLink(initialLink.toString());
      }
      
      // 2. Слушаем входящие deep links (когда приложение уже запущено)
      _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
        debugPrint('🔗 Received deep link: $uri');
        _handleIncomingLink(uri.toString());
      }, onError: (e) {
        debugPrint('❌ Deep link stream error: $e');
      });
      
      debugPrint('✅ AppLinks listener activated');
    } catch (e) {
      debugPrint('⚠️ AppLinks setup error: $e');
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
        // Реферальная ссылка - проверяем авторизацию и применяем промокод если нужно
        _handleReferralLink(uri);
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

        // ✅ Сохраняем промокод в локальное хранилище для будущего применения
        UserDataManager.savePromoCode(ref).then((_) {
          debugPrint('💾 Saved referral promo code to local storage: $ref');
        }).catchError((e) {
          debugPrint('⚠️ Failed to save promo code: $e');
        });

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

  /// Обработка реферальной ссылки
  /// Если пользователь авторизован и еще не применял промокод - применяем автоматически
  void _handleReferralLink(Uri uri) async {
    final ref = uri.queryParameters['ref'];
    if (ref == null || ref.isEmpty) {
      _navigateToDiscount();
      return;
    }

    debugPrint('🔗 Processing referral link with code: $ref');

    // Проверяем авторизацию
    final isLoggedIn = await UserDataManager.isUserLoggedIn();
    
    if (isLoggedIn) {
      // Пользователь авторизован - проверяем, был ли уже применен промокод
      final user = await UserDataManager.getUser();
      final hasUsedPromoCode = user?.userPromoCode != null && user!.userPromoCode! > 0;
      
      if (!hasUsedPromoCode) {
        // Промокод еще не был применен - применяем автоматически
        debugPrint('💎 User is logged in, applying promo code automatically: $ref');
        
        try {
          // Получаем репозиторий для применения промокода
          final discountRepository = serviceLocator<DiscountRepository>();
          final result = await discountRepository.postPromoCode(promoCode: ref);
          
          result.fold(
            (failure) {
              debugPrint('⚠️ Failed to apply promo code: ${failure.message}');
              
              // Показываем тост с ошибкой
              _showErrorToast(failure.message ?? 'Не удалось применить промокод');
              
              // Навигируем на страницу скидок даже если ошибка
              _navigateToDiscount();
            },
            (success) {
              debugPrint('✅ Promo code applied successfully via deep link');
              // Очищаем сохраненный промокод
              UserDataManager.clearPromoCode();
              
              // Навигируем на главную
              _safeNavigate(() {
                final navigator = navigatorKey.currentState;
                if (navigator == null) return;
                
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const NavScreen(initialTab: 0),
                  ),
                  (route) => false,
                );
              });
              
              // Показываем диалог успешного применения
              Future.delayed(const Duration(milliseconds: 500), () {
                if (navigatorKey.currentContext != null) {
                  PromoCodeSuccessDialog.show(
                    navigatorKey.currentContext!,
                    promoCode: ref,
                  );
                }
              });
            },
          );
        } catch (e) {
          debugPrint('❌ Error applying promo code: $e');
          _showErrorToast('Произошла ошибка при применении промокода');
          _navigateToDiscount();
        }
      } else {
        debugPrint('ℹ️ User already has used promo code, navigating to discount page');
        // Очищаем сохраненный промокод
        await UserDataManager.clearPromoCode();
        
        // Показываем тост что промокод уже был использован
        _showWarningToast();
        
        _navigateToDiscount();
      }
    } else {
      // Пользователь не авторизован - показываем тост и навигируем
      debugPrint('👤 User not logged in, promo code saved for later');
      _showInfoToast(ref);
      _navigateToDiscount();
    }
  }
  
  /// Показать тост об ошибке
  void _showErrorToast(String message) {
    // Используем WidgetsBinding для гарантии что UI построен
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        final context = navigatorKey.currentContext;
        final overlay = navigatorKey.currentState?.overlay;
        if (context != null && context.mounted) {
          TopToast.showError(
            context,
            title: 'Ошибка',
            message: message,
            duration: const Duration(seconds: 5),
            overlayState: overlay,
          );
        }
      });
    });
  }
  
  /// Показать тост что промокод уже использован
  void _showWarningToast() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        final context = navigatorKey.currentContext;
        final overlay = navigatorKey.currentState?.overlay;
        if (context != null && context.mounted) {
          final l10n = AppLocalizations.of(context);
          TopToast.showWarning(
            context,
            title: l10n?.promoCodeAlreadyUsedTitle ?? 'Промокод уже использован',
            message: l10n?.promoCodeAlreadyUsedMessage ?? 'Вы уже применяли реферальный промокод ранее. Повторное использование невозможно.',
            duration: const Duration(seconds: 5),
            overlayState: overlay,
          );
        }
      });
    });
  }
  
  /// Показать информационный тост (для неавторизованных)
  void _showInfoToast(String promoCode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        final context = navigatorKey.currentContext;
        final overlay = navigatorKey.currentState?.overlay;
        if (context != null && context.mounted) {
          final l10n = AppLocalizations.of(context);
          TopToast.showInfo(
            context,
            title: l10n?.promoCodeSavedTitle ?? 'Промокод сохранён',
            message: l10n?.promoCodeSavedMessage(promoCode) ?? 'Промокод $promoCode будет применён после авторизации.',
            duration: const Duration(seconds: 4),
            overlayState: overlay,
          );
        }
      });
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
    _refParameterController.close();
    _deepLinkController.close();
  }
}
