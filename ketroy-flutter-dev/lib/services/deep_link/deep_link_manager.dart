import 'dart:async';
import 'dart:developer';

import 'package:chottu_link/chottu_link.dart';
import 'package:flutter/material.dart';

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
    debugPrint('🔗 Received link: $link');

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
  }
}
