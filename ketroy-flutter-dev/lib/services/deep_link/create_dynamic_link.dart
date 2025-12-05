import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

/// Константы для deep links
class DeepLinkConstants {
  /// Основной домен для deep links
  static const String domain = 'app.ketroy-shop.kz';
  
  /// Базовый URL для deep links
  static const String baseUrl = 'https://$domain';
  
  /// Ссылка на Google Play
  static const String googlePlayUrl = 
      'https://play.google.com/store/apps/details?id=kz.ketroy.shop';
  
  /// Ссылка на App Store (замените YOUR_APP_ID на реальный ID)
  static const String appStoreUrl = 
      'https://apps.apple.com/app/ketroy-shop/id6743387498';
  
  /// URL схема приложения
  static const String appScheme = 'ketroy';
}

/// Сервис для создания и шаринга ссылок Ketroy
class KetroyDynamicLinksCallback {
  /// Создание пригласительной ссылки с реферальным кодом
  /// 
  /// [referralCode] - промокод пользователя
  /// [onSuccess] - callback при успешном создании ссылки
  /// [onError] - callback при ошибке
  static void createInviteLink({
    required String referralCode,
    required Function(String link) onSuccess,
    required Function(String error) onError,
  }) {
    try {
      // Создаем ссылку с реферальным кодом
      final link = '${DeepLinkConstants.baseUrl}/invite?ref=$referralCode';
      
      debugPrint('✅ Invite link created: $link');
      onSuccess(link);
    } catch (e) {
      debugPrint('❌ Error creating invite link: $e');
      onError(e.toString());
    }
  }

  /// Создание ссылки на конкретный экран
  static String createScreenLink({
    required String screen,
    Map<String, String>? params,
  }) {
    final uri = Uri(
      scheme: 'https',
      host: DeepLinkConstants.domain,
      path: '/$screen',
      queryParameters: params,
    );
    return uri.toString();
  }

  /// Создание ссылки на товар
  static String createProductLink(String productId) {
    return '${DeepLinkConstants.baseUrl}/product/$productId';
  }

  /// Создание ссылки на подарок
  static String createGiftLink(String giftId) {
    return '${DeepLinkConstants.baseUrl}/gift/$giftId';
  }

  /// Создание ссылки на профиль
  static String createProfileLink(String userId) {
    return '${DeepLinkConstants.baseUrl}/profile/$userId';
  }

  /// Получить ссылку на магазин приложений для текущей платформы
  static String getStoreLink() {
    if (Platform.isIOS) {
      return DeepLinkConstants.appStoreUrl;
    } else {
      return DeepLinkConstants.googlePlayUrl;
    }
  }
}

/// Сервис для шаринга ссылок и промокодов
class KetroyShareService {
  /// Получить позицию для sharePositionOrigin на iOS
  /// Это обязательно для iPad и рекомендуется для iPhone
  static Rect? _getSharePositionOrigin(BuildContext context) {
    try {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        final Offset position = box.localToGlobal(Offset.zero);
        final Size size = box.size;
        return Rect.fromLTWH(
          position.dx,
          position.dy,
          size.width,
          size.height,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Could not get share position origin: $e');
    }
    // Fallback: центр экрана
    return null;
  }

  /// Поделиться реферальной ссылкой
  /// 
  /// [referralCode] - промокод пользователя
  /// [context] - контекст для получения локализации
  /// [onError] - callback при ошибке
  static Future<void> shareReferralLink({
    required String referralCode,
    required BuildContext context,
    Function(String error)? onError,
  }) async {
    try {
      final l10n = AppLocalizations.of(context);
      if (l10n == null) {
        onError?.call('Localization not available');
        return;
      }

      // Создаем ссылку
      final link = '${DeepLinkConstants.baseUrl}/invite?ref=$referralCode';
      
      // Формируем текст для шаринга
      final shareText = l10n.joinKetroy(link);
      
      debugPrint('📤 Sharing referral link: $link');
      
      // Получаем позицию для iOS sharePositionOrigin
      final sharePositionOrigin = _getSharePositionOrigin(context);
      
      // Используем share_plus для шаринга
      final result = await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: l10n.ketroyInvitation,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      
      debugPrint('📤 Share result: ${result.status}');
      
    } catch (e) {
      debugPrint('❌ Error sharing referral link: $e');
      onError?.call(e.toString());
    }
  }

  /// Поделиться простым текстом с ссылкой
  static Future<void> shareText({
    required String text,
    String? subject,
    BuildContext? context,
  }) async {
    try {
      Rect? sharePositionOrigin;
      if (context != null) {
        sharePositionOrigin = _getSharePositionOrigin(context);
      }
      
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: subject,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error sharing text: $e');
    }
  }

  /// Поделиться ссылкой на приложение (для скачивания)
  static Future<void> shareAppLink({
    required BuildContext context,
  }) async {
    try {
      final storeLink = KetroyDynamicLinksCallback.getStoreLink();
      // Используем простой текст для шаринга приложения
      const text = '🛍️ Скачайте приложение Ketroy Shop и получайте эксклюзивные скидки!';
      
      // Получаем позицию для iOS sharePositionOrigin
      final sharePositionOrigin = _getSharePositionOrigin(context);
      
      await SharePlus.instance.share(
        ShareParams(
          text: '$text\n$storeLink',
          subject: 'Ketroy Shop',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error sharing app link: $e');
    }
  }
}
