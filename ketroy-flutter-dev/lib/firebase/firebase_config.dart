// import 'dart:developer';

// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:ketroy_app/features/auth/presentation/pages/sign_up_page.dart';
// import 'package:ketroy_app/firebase_options.dart';

// class FirebaseConfig {
//   static GlobalKey<NavigatorState>? _navigatorKey;
//   static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   static final FlutterLocalNotificationsPlugin
//       _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

//   static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
//     'high_importance_channel',
//     'High Importance Notifications',
//     description: 'This channel is used for important notifications.',
//     importance: Importance.max,
//   );

//   static Future<void> init() async {
//     await Firebase.initializeApp(
//         options: DefaultFirebaseOptions.currentPlatform);

//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//     await _flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(_channel);

//     FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
//       final notification = message.notification;
//       final android = message.notification?.android;

//       if (notification != null && android != null) {
//         _flutterLocalNotificationsPlugin.show(
//           notification.hashCode,
//           notification.title,
//           notification.body,
//           NotificationDetails(
//             android: AndroidNotificationDetails(
//               _channel.id,
//               _channel.name,
//               channelDescription: _channel.description,
//               icon: 'ic_launcher',
//             ),
//           ),
//         );
//       }
//     });

//     final token = await _messaging.getToken();
//     log('🔐 FCM Token: $token');
//   }

//   static void initNavigation(GlobalKey<NavigatorState> navigatorKey) {
//     _navigatorKey = navigatorKey;

//     // Обработка, когда уведомление открыто из свернутого состояния
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       _handleNotificationClick(message);
//     });

//     // Обработка, когда приложение запускается из закрытого состояния через уведомление
//     FirebaseMessaging.instance.getInitialMessage().then((message) {
//       if (message != null) {
//         _handleNotificationClick(message);
//       }
//     });
//   }

//   static Future<void> requestNotificationPermission() async {
//     NotificationSettings settings = await _messaging.getNotificationSettings();
//     if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
//       settings = await FirebaseMessaging.instance.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//         announcement: true,
//       );
//     }

//     debugPrint(
//         '🔔 Notification permission status: ${settings.authorizationStatus}');
//   }

//   static void _handleNotificationClick(RemoteMessage message) {
//     _navigatorKey?.currentState?.push(MaterialPageRoute(
//         builder: (context) => SignUpPage(
//               codes: [],
//             )));
//   }

//   static Future<void> _firebaseMessagingBackgroundHandler(
//       RemoteMessage message) async {
//     await Firebase.initializeApp();
//   }
// }
