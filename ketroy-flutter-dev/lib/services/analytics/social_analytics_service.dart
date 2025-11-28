/// ============================================
/// KETROY APP - SOCIAL ANALYTICS SERVICE
/// ============================================
/// Сервис для отслеживания нажатий на социальные сети
library;

import 'package:flutter/foundation.dart';
import 'package:ketroy_app/core/internet_services/dio_client.dart';

/// Типы социальных сетей для аналитики
enum SocialType {
  whatsapp,
  instagram,
  twoGis,
}

/// Источники (страницы) откуда был клик
enum SourcePage {
  shopDetail,
  newsDetail,
  navBar,
  partners,
  certificate,
}

/// Параметры для трекинга социального клика
class SocialClickParams {
  final SocialType socialType;
  final SourcePage sourcePage;
  final int? sourceId;
  final String? sourceName;
  final String? city;
  final String? url;

  const SocialClickParams({
    required this.socialType,
    required this.sourcePage,
    this.sourceId,
    this.sourceName,
    this.city,
    this.url,
  });

  Map<String, dynamic> toJson() => {
        'social_type': socialType.name == 'twoGis' ? '2gis' : socialType.name,
        'source_page': _sourcePageToString(sourcePage),
        if (sourceId != null) 'source_id': sourceId,
        if (sourceName != null) 'source_name': sourceName,
        if (city != null) 'city': city,
        if (url != null) 'url': url,
      };

  String _sourcePageToString(SourcePage page) {
    switch (page) {
      case SourcePage.shopDetail:
        return 'shop_detail';
      case SourcePage.newsDetail:
        return 'news_detail';
      case SourcePage.navBar:
        return 'nav_bar';
      case SourcePage.partners:
        return 'partners';
      case SourcePage.certificate:
        return 'certificate';
    }
  }
}

/// Сервис аналитики социальных сетей
class SocialAnalyticsService {
  static final SocialAnalyticsService _instance =
      SocialAnalyticsService._internal();
  factory SocialAnalyticsService() => _instance;
  SocialAnalyticsService._internal();

  final DioClient _dioClient = DioClient.instance;

  /// Отправить событие клика по социальной сети
  /// Метод работает асинхронно и не блокирует UI
  Future<void> trackSocialClick(SocialClickParams params) async {
    try {
      await _dioClient.post(
        '/analytics/social-click',
        data: params.toJson(),
      );
      debugPrint(
          '📊 Social click tracked: ${params.socialType.name} from ${params.sourcePage.name}');
    } catch (e) {
      // Не прерываем работу приложения при ошибке аналитики
      debugPrint('⚠️ Failed to track social click: $e');
    }
  }

  /// Удобные методы для быстрого трекинга

  /// Трекинг клика WhatsApp с магазина
  void trackWhatsAppFromShop({
    required int shopId,
    required String shopName,
    String? city,
    String? url,
  }) {
    trackSocialClick(SocialClickParams(
      socialType: SocialType.whatsapp,
      sourcePage: SourcePage.shopDetail,
      sourceId: shopId,
      sourceName: shopName,
      city: city,
      url: url,
    ));
  }

  /// Трекинг клика Instagram с магазина
  void trackInstagramFromShop({
    required int shopId,
    required String shopName,
    String? url,
  }) {
    trackSocialClick(SocialClickParams(
      socialType: SocialType.instagram,
      sourcePage: SourcePage.shopDetail,
      sourceId: shopId,
      sourceName: shopName,
      url: url,
    ));
  }

  /// Трекинг клика 2GIS с магазина
  void track2GisFromShop({
    required int shopId,
    required String shopName,
    String? url,
  }) {
    trackSocialClick(SocialClickParams(
      socialType: SocialType.twoGis,
      sourcePage: SourcePage.shopDetail,
      sourceId: shopId,
      sourceName: shopName,
      url: url,
    ));
  }

  /// Трекинг клика WhatsApp со страницы новости
  void trackWhatsAppFromNews({
    required int newsId,
    required String newsTitle,
    String? city,
    String? url,
  }) {
    trackSocialClick(SocialClickParams(
      socialType: SocialType.whatsapp,
      sourcePage: SourcePage.newsDetail,
      sourceId: newsId,
      sourceName: newsTitle,
      city: city,
      url: url,
    ));
  }

  /// Трекинг клика WhatsApp из навбара/меню
  void trackWhatsAppFromNavBar({
    String? city,
    String? url,
  }) {
    trackSocialClick(SocialClickParams(
      socialType: SocialType.whatsapp,
      sourcePage: SourcePage.navBar,
      city: city,
      url: url,
    ));
  }

  /// Трекинг клика Instagram из навбара/меню
  void trackInstagramFromNavBar({
    String? city,
    String? url,
  }) {
    trackSocialClick(SocialClickParams(
      socialType: SocialType.instagram,
      sourcePage: SourcePage.navBar,
      city: city,
      url: url,
    ));
  }

  /// Трекинг клика WhatsApp со страницы партнеров
  void trackWhatsAppFromPartners({
    String? url,
  }) {
    trackSocialClick(SocialClickParams(
      socialType: SocialType.whatsapp,
      sourcePage: SourcePage.partners,
      url: url,
    ));
  }

  /// Трекинг клика WhatsApp со страницы сертификатов
  void trackWhatsAppFromCertificate({
    String? city,
    String? url,
  }) {
    trackSocialClick(SocialClickParams(
      socialType: SocialType.whatsapp,
      sourcePage: SourcePage.certificate,
      city: city,
      url: url,
    ));
  }
}

/// Глобальный instance для удобного доступа
final socialAnalytics = SocialAnalyticsService();

