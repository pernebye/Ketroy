import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';
import 'package:ketroy_app/core/transitions/slide_over_page_route.dart';
import 'package:ketroy_app/features/my_gifts/presentation/pages/gifts_page.dart';
import 'package:ketroy_app/features/news/presentation/pages/news_page_detail.dart';
import 'package:ketroy_app/features/notification/domain/entities/notification_entity.dart';
import 'package:ketroy_app/features/notification/presentation/pages/notification_page.dart';
import 'package:ketroy_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Событие нового подарка для обновления UI
class NewGiftEvent {
  final String? giftName;
  final String? giftImage;
  final DateTime timestamp;

  NewGiftEvent({
    this.giftName,
    this.giftImage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    debugPrint('🔔 Background handler started: ${message.messageId}');

    // ✅ КРИТИЧЕСКИ ВАЖНО: Инициализируем Firebase в background handler
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized in background handler');

    // Инициализируем flutter_app_badger и увеличиваем badge
    await _incrementBadgeInBackground();

    debugPrint('✅ Background message handled: ${message.messageId}');
    debugPrint('📱 Title: ${message.notification?.title}');
    debugPrint('📱 Body: ${message.notification?.body}');
    debugPrint('📊 Data: ${message.data}');
  } catch (e) {
    debugPrint('Error handling background message: $e');
  }
}

// ✅ Вспомогательная функция для увеличения badge в background
Future<void> _incrementBadgeInBackground() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt('badge_count') ?? 0;
    int newCount = currentCount + 1;

    await prefs.setInt('badge_count', newCount);

    if (await FlutterAppBadgeControl.isAppBadgeSupported()) {
      await FlutterAppBadgeControl.updateBadgeCount(newCount);
      debugPrint('🔴 Background badge updated: $newCount');
    }
  } catch (e) {
    debugPrint('❌ Error updating background badge: $e');
  }
}

class NotificationServices {
  NotificationServices._();
  static final NotificationServices instance = NotificationServices._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterNotificationsInitialized = false;
  String? _fcmToken;
  int _badgeCount = 0;

  // Stream для событий новых подарков
  final _newGiftController = StreamController<NewGiftEvent>.broadcast();
  
  /// Stream для подписки на события новых подарков
  Stream<NewGiftEvent> get onNewGift => _newGiftController.stream;

  String? get fcmToken => _fcmToken;
  int get badgeCount => _badgeCount;
  
  /// Уведомить о новом подарке
  void notifyNewGift({String? giftName, String? giftImage}) {
    debugPrint('🎁 Broadcasting new gift event: $giftName');
    _newGiftController.add(NewGiftEvent(
      giftName: giftName,
      giftImage: giftImage,
    ));
  }

  Future<void> initialize() async {
    try {
      debugPrint('🚀 Initializing NotificationServices...');

      // ✅ ВАЖНО: Регистрируем background handler В САМОМ НАЧАЛЕ
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      debugPrint('✅ Background message handler registered');

      // Проверяем поддержку значков и восстанавливаем счетчик
      await _checkBadgeSupport();
      await restoreBadgeCount();

      //Request permision
      await _requestPermission();

      //setup message handlers
      await _setupMessageHandlers();
      await setupFlutterNotifications();

      await _messaging.setForegroundNotificationPresentationOptions(
          alert: true, badge: true, sound: true);

      // ✅ ИСПРАВЛЕНИЕ: Получаем APNS токен для iOS перед FCM токеном
      if (Platform.isIOS) {
        try {
          // Ждем получения APNS токена с таймаутом
          final apnsToken = await _messaging.getAPNSToken();
          if (apnsToken != null) {
            debugPrint(
                '✅ APNS token received: ${apnsToken.substring(0, 20)}...');
          } else {
            debugPrint('⚠️ APNS token is null, waiting...');
            // Ждем немного больше для получения APNS токена
            await Future.delayed(const Duration(seconds: 3));
            final retryApnsToken = await _messaging.getAPNSToken();
            if (retryApnsToken != null) {
              debugPrint(
                  '✅ APNS token received after retry: ${retryApnsToken.substring(0, 20)}...');
            } else {
              debugPrint('❌ APNS token still null after retry');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error getting APNS token: $e');
          // Продолжаем выполнение, так как это не критическая ошибка
        }
      }

      // Теперь получаем FCM токен
      await _getFCMToken();

      //subscribe to all devices/broadcasr
      subscribeToTopic('all_devices');

      debugPrint('✅ Notification services initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing notification services: $e');
      rethrow;
    }
  }

  Future<void> _checkBadgeSupport() async {
    try {
      bool isSupported = await FlutterAppBadgeControl.isAppBadgeSupported();
      debugPrint('📱 Badge support: $isSupported');

      if (isSupported) {
        // Инициализируем счетчик значка
        await restoreBadgeCount();
      }
    } catch (e) {
      debugPrint('❌ Error checking badge support: $e');
    }
  }

  Future<void> _getFCMToken() async {
    try {
      // Для iOS может потребоваться несколько попыток
      int maxRetries = Platform.isIOS ? 5 : 2;
      int retryCount = 0;

      while (retryCount < maxRetries) {
        try {
          final token = await _messaging.getToken();
          if (token != null) {
            _fcmToken = token;
            debugPrint('✅ FCM token received: $token');
            return;
          }
        } catch (e) {
          retryCount++;
          debugPrint('⚠️ Attempt $retryCount failed to get FCM token: $e');

          if (retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: retryCount * 2));
          }
        }
      }

      debugPrint('❌ Failed to get FCM token after $maxRetries attempts');
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
      );

      debugPrint('Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('❌ User denied notifications permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.authorized) {
        debugPrint('✅ User granted notifications permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('🔶 User granted provisional notifications permission');
      }
    } catch (e) {
      debugPrint('Error requesting permission: $e');
    }
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterNotificationsInitialized) {
      return;
    }

    try {
// android setup
      const channel = AndroidNotificationChannel(
          'high_importance_channel', 'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.high,
          showBadge: true,
          playSound: true,
          enableVibration: true);

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // ios setup
      const initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: false,
        notificationCategories: [],
      );

      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifications.initialize(initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse details) {
        _handleNotificationTap(details);
      });

      _isFlutterNotificationsInitialized = true;
      debugPrint('✅ Flutter notifications initialized');
    } catch (e) {
      debugPrint('❌ Error setting up flutter notifications: $e');
      rethrow;
    }
  }

  Future<void> showNotification(RemoteMessage message) async {
    try {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification == null) {
        debugPrint('⚠️ Notification is null, skipping display');
        return;
      }

      // Создаем payload из данных сообщения
      final payload = jsonEncode(message.data);

      await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
              android: android != null
                  ? AndroidNotificationDetails(
                      'high_importance_channel',
                      'High Importance Notifications',
                      channelDescription:
                          'This channel is used for important notifications.',
                      importance: Importance.high,
                      priority: Priority.high,
                      icon: '@mipmap/ic_launcher',
                      ticker: notification.title,
                      playSound: true, // ✅ ДОБАВЛЕНО
                      enableVibration: true, // ✅ ДОБАВЛЕНО
                      styleInformation: BigTextStyleInformation(
                        notification.body ?? '',
                        contentTitle: notification.title,
                      ),
                    )
                  : null,
              iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                  sound: 'default',
                  badgeNumber: _badgeCount)),
          payload: payload);
      debugPrint('📱 Notification shown: ${notification.title}');
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

  Future<void> _setupMessageHandlers() async {
    try {
      //Foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('📨 Foreground message received: ${message.messageId}');
        debugPrint('📱 Title: ${message.notification?.title}');
        debugPrint('📱 Body: ${message.notification?.body}');
        debugPrint('📊 Data: ${message.data}');

        // ✅ Увеличиваем badge для foreground уведомлений
        incrementBadge();

        // ✅ Проверяем тип уведомления и уведомляем о новом подарке
        _checkAndNotifyGiftEvent(message);

        if (Platform.isAndroid) {
          showNotification(message);
        }
      });

      //background message
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('📨 Background message opened app: ${message.messageId}');
        _handleBackgroundMessage(message);
      });

      //opened app
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📨 Initial message: ${initialMessage.messageId}');
        // Задержка для завершения инициализации приложения
        Future.delayed(const Duration(seconds: 1), () {
          _handleBackgroundMessage(initialMessage);
        });
      }
      debugPrint('✅ Message handlers set up');
    } catch (e) {
      debugPrint('❌ Error setting up message handlers: $e');
    }
  }

  void _handleNotificationTap(NotificationResponse details) {
    try {
      clearBadge();

      if (details.payload != null && details.payload!.isNotEmpty) {
        final data = jsonDecode(details.payload!);
        _navigateBasedOnData(data);
      } else {
        // Навигация по умолчанию
        _navigateToNotifications();
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
      // Fallback навигация
      _navigateToNotifications();
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    try {
      debugPrint('🔄 Handling background message: ${message.data}');

      // Сбрасываем счетчик значка при открытии приложения через уведомление
      clearBadge();

      _navigateBasedOnData(message.data);
    } catch (e) {
      debugPrint('❌ Error handling background message: $e');
      _navigateToNotifications();
    }
  }

  void handleMessageOpenedApp(BuildContext context) {
    _messaging.getInitialMessage().then((remoteMessage) {
      if (remoteMessage != null) {
        if (!context.mounted) {
          return;
        }
        clearBadge();
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const GiftsPage()));
      }
    });
  }

  void _navigateBasedOnData(Map<String, dynamic> data) {
    try {
      final type = data['type'] as String?;
      final route = data['route'] as String?;

      debugPrint('🧭 Navigation data - type: $type, route: $route, data: $data');

      // Обработка уведомлений о новостях
      if (type == 'news') {
        final newsIdStr = data['news_id'] as String?;
        if (newsIdStr != null) {
          final newsId = int.tryParse(newsIdStr);
          if (newsId != null) {
            debugPrint('📰 Navigating to news detail: $newsId');
            _navigateToNewsDetail(newsId);
            return;
          }
        }
      }

      // По умолчанию переходим на уведомления
      _navigateToNotifications();
    } catch (e) {
      debugPrint('❌ Error in navigation logic: $e');
      _navigateToNotifications();
    }
  }

  // Навигация на страницу детали новости
  void _navigateToNewsDetail(int newsId) {
    _safeNavigate(() {
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;

      // Очищаем весь стек и переходим к главному экрану
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => const NavScreen(
                  initialTab: 0,
                )),
        (route) => route.isFirst,
      );

      // Затем открываем страницу новости
      Future.delayed(const Duration(milliseconds: 100), () {
        navigator.push(
          NewsDetailPageRoute(
            newsId: newsId,
            newsTitle: '', // Заголовок загрузится из API
          ),
        );
      });

      debugPrint('✅ Navigated to news detail: $newsId');
    });
  }

  /// Проверяет тип уведомления и транслирует событие о новом подарке
  void _checkAndNotifyGiftEvent(RemoteMessage message) {
    try {
      final data = message.data;
      final type = data['type'] as String?;
      
      // Проверяем типы уведомлений, связанных с подарками
      if (type == 'gift' || 
          type == 'new_gift' || 
          type == 'gift_received' ||
          type == 'gift_issuance' ||
          type == 'pending_gift' ||
          data.containsKey('gift_id') ||
          data.containsKey('gift_group_id')) {
        
        debugPrint('🎁 Gift notification detected, broadcasting event');
        notifyNewGift(
          giftName: data['gift_name'] ?? message.notification?.title,
          giftImage: data['gift_image'],
        );
      }
      
      // Также проверяем по ключевым словам в заголовке/теле
      final title = message.notification?.title?.toLowerCase() ?? '';
      final body = message.notification?.body?.toLowerCase() ?? '';
      
      if (title.contains('подарок') || 
          title.contains('gift') ||
          body.contains('подарок') ||
          body.contains('gift')) {
        debugPrint('🎁 Gift keyword detected in notification, broadcasting event');
        notifyNewGift(
          giftName: message.notification?.title,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error checking gift event: $e');
    }
  }

  // Навигация на страницу уведомлений через Navigator.push
  void _navigateToNotifications() {
    _safeNavigate(() {
      // Получаем текущий контекст навигатора
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;

      // Очищаем весь стек и переходим к главному экрану
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => const NavScreen(
                  initialTab: 0,
                )),
        (route) => route.isFirst,
      );

      Future.delayed(const Duration(milliseconds: 100), () {
        navigator.push(
          SlideOverPageRoute(page: const NotificationPage()),
        );
      });
    });
  }

  // void _navigateToGifts() {
  //   _safeNavigate(() {
  //     // Закрываем текущие экраны до корневого
  //     navigatorKey.currentState?.popUntil((route) => route.isFirst);

  //     // ✅ Используем публичный метод вместо setState
  //     NavScreen.globalKey.currentState?.switchToTab(3, popToFirst: true);
  //   });
  // }

  void _safeNavigate(VoidCallback navigationCallback) {
    try {
      if (navigatorKey.currentState != null) {
        navigationCallback();
        debugPrint('✅ Navigation completed');
      } else {
        debugPrint('⚠️ Navigator not ready, delaying navigation');
        // Повторяем попытку через секунду
        Future.delayed(const Duration(seconds: 1), () {
          if (navigatorKey.currentState != null) {
            navigationCallback();
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint('Subscribed to $topic');
  }

  Future<void> updateBadgeFromNotifications(
      List<NotificationEntity> notifications) async {
    try {
      // Считаем только непрочитанные уведомления
      final unreadCount = notifications
          .where((notification) => !notification.isRead)
          .length;

      debugPrint(
          '📊 Total notifications: ${notifications.length}, Unread: $unreadCount');
      await updateBadge(unreadCount);
    } catch (e) {
      debugPrint('❌ Error updating badge from notifications: $e');
    }
  }

  Future<void> incrementBadgeInBackground() async {
    await _incrementBadgeInBackground();
  }

  Future<void> updateBadge(int count) async {
    try {
      _badgeCount = count;

      // Сохраняем в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('badge_count', count);

      if (await FlutterAppBadgeControl.isAppBadgeSupported()) {
        if (count > 0) {
          await FlutterAppBadgeControl.updateBadgeCount(count);
          debugPrint('🔴 Badge updated: $count');
        } else {
          await FlutterAppBadgeControl.removeBadge();
          debugPrint('⭕ Badge removed');
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating badge: $e');
    }
  }

  /// Увеличивает счетчик значка на 1
  Future<void> incrementBadge() async {
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt('badge_count') ?? _badgeCount;
    await updateBadge(currentCount + 1);
  }

  /// Уменьшает счетчик значка на указанное количество
  Future<void> decrementBadge([int count = 1]) async {
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt('badge_count') ?? _badgeCount;
    int newCount = currentCount - count;
    if (newCount < 0) newCount = 0;
    await updateBadge(newCount);
  }

  /// Очищает значок приложения
  Future<void> clearBadge() async {
    await updateBadge(0);
  }

  /// Устанавливает конкретное значение для значка
  Future<void> setBadge(int count) async {
    await updateBadge(count);
  }

  /// Восстанавливает счетчик значка из SharedPreferences при запуске приложения
  Future<void> restoreBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int currentCount = prefs.getInt('badge_count') ?? 0;
      _badgeCount = currentCount;

      if (currentCount > 0 &&
          await FlutterAppBadgeControl.isAppBadgeSupported()) {
        await FlutterAppBadgeControl.updateBadgeCount(currentCount);
        debugPrint('🔄 Badge restored from storage: $currentCount');
      }
    } catch (e) {
      debugPrint('❌ Error restoring badge: $e');
    }
  }

  // Метод для отправки токена на сервер
  Future<void> sendTokenToServer() async {
    try {
      if (_fcmToken != null) {
        // Здесь можно отправить токен на ваш сервер
        debugPrint('📤 Sending token to server: $_fcmToken');
        // await apiService.sendFcmToken(_fcmToken!);
      }
    } catch (e) {
      debugPrint('❌ Error sending token to server: $e');
    }
  }

  // Метод для обновления токена
  void _listenToTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      debugPrint('🔄 FCM token refreshed: $token');
      sendTokenToServer();
    });
  }

  // Добавляем слушатель обновления токена в initialize
  Future<void> initializeWithTokenListener() async {
    await initialize();
    _listenToTokenRefresh();
  }
}
