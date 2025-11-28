import 'dart:async';

import 'package:chottu_link/chottu_link.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ketroy_app/core/constants/constants.dart';
import 'package:ketroy_app/core/constants/hive_constants.dart';
import 'package:ketroy_app/core/internet_services/cache_service/custom_cache_manager.dart';
import 'package:ketroy_app/core/model/active_gift_model.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/core/widgets/error_app.dart';
import 'package:ketroy_app/core/widgets/error_screen.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/core/widgets/main_screen.dart';
import 'package:ketroy_app/features/ai/presentation/bloc/ai_bloc.dart';
import 'package:ketroy_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ketroy_app/features/bonus/presentation/bloc/bonus_bloc.dart';
import 'package:ketroy_app/features/certificates/presentation/bloc/certificate_bloc.dart';
import 'package:ketroy_app/features/discount/presentation/bloc/discount_bloc.dart';
import 'package:ketroy_app/features/my_gifts/presentation/bloc/gifts_bloc.dart';
import 'package:ketroy_app/features/news/domain/entities/actuals_entity.dart';
import 'package:ketroy_app/features/news/presentation/bloc/news_bloc.dart';
import 'package:ketroy_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:ketroy_app/features/partners/presentation/bloc/partners_bloc.dart';
import 'package:ketroy_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:ketroy_app/features/shop/presentation/bloc/shop_bloc.dart';
import 'package:ketroy_app/features/shop_detail/presentation/bloc/shop_detail_bloc.dart';
import 'package:ketroy_app/features/stories/presentation/pages/stories.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:ketroy_app/services/localization/localization_service.dart';
import 'package:ketroy_app/services/notification_services.dart';
import 'package:ketroy_app/services/deep_link/deep_link_manager.dart';
import 'package:ketroy_app/services/shared_preferences_service.dart';
import 'package:ketroy_app/services/splash/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final DeepLinkManager globalDeepLinkManager = DeepLinkManager();
void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // ✅ СРАЗУ устанавливаем белый фон системного UI — до всего остального!
    // Это предотвращает чёрный фон при hot reload
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    await _initializeBasicServices();

    // СРАЗУ ПОКАЗЫВАЕМ SPLASH SCREEN
    runApp(const SplashWrapper());
  }, _handleGlobalError);
}

/// Initialize basic services required before app starts
Future<void> _initializeBasicServices() async {
  try {
    debugPrint('🚀 Initializing basic services...');

    // ✅ Firebase инициализация (пропускаем для web, т.к. не настроен)
    try {
      await Firebase.initializeApp();
      debugPrint('✅ Firebase initialized in main');
    } catch (e) {
      debugPrint('⚠️ Firebase initialization skipped (web not configured): $e');
      // Продолжаем работу без Firebase - не критично
    }

    // ChottuLink инициализация (пропускаем для web)
    try {
      await ChottuLink.init(apiKey: chottuLinkApiKey);
      debugPrint('✅ ChottuLink initialized');
    } catch (e) {
      debugPrint(
          '⚠️ ChottuLink initialization skipped (web not supported): $e');
    }

    // Ориентация экрана (может не работать на web)
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      debugPrint('✅ Screen orientation set');
    } catch (e) {
      debugPrint('⚠️ Screen orientation not set (web): $e');
    }
  } catch (e) {
    debugPrint('❌ Error in basic services initialization: $e');
    // НЕ делаем rethrow - даем приложению запуститься даже с ошибками
  }
}

/// Global error handler
void _handleGlobalError(Object error, StackTrace stackTrace) {
  debugPrint('❌ Global error: $error');

  if (_isCacheError(error)) {
    debugPrint('🧹 Cache database error detected, clearing cache...');
    _handleCacheError();
  }

  debugPrint('Stack trace: $stackTrace');
}

/// Check if error is cache-related
bool _isCacheError(Object error) {
  final errorString = error.toString();
  return errorString.contains('readonly database') ||
      errorString.contains('DatabaseException') ||
      errorString.contains('CacheStore');
}

// Обработка ошибок кэша
void _handleCacheError() {
  // Запускаем очистку кэша асинхронно
  Future.microtask(() async {
    try {
      await CustomCacheManager.clearCache();
      debugPrint('✅ Cache cleared after error');
    } catch (e) {
      debugPrint('❌ Failed to clear cache after error: $e');
    }
  });
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    globalDeepLinkManager.initialize();
  }

  @override
  void dispose() {
    globalDeepLinkManager.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('🚀 Starting app initialization...');

      // Показываем splash минимум 2 секунды для красоты
      final initFuture = _initializeServices();
      final delayFuture = Future.delayed(splashDuration);

      await Future.wait([initFuture, delayFuture]);

      debugPrint('✅ Services initialized successfully');

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error during app initialization: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _initError = e.toString();
        });
      }
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Firebase инициализация (пропускаем для web)
      try {
        await Firebase.initializeApp();
        debugPrint('✅ Firebase initialized');
      } catch (e) {
        debugPrint('⚠️ Firebase initialization skipped: $e');
      }

      // Hive база данных
      await _initializeHive();
      debugPrint('✅ Hive initialized');

      // Dependency injection
      await initDependencies();
      debugPrint('✅ Dependencies initialized');

      await _initializeNotifications();
    } catch (e) {
      debugPrint('❌ Service initialization failed: $e');
      rethrow;
    }
  }

  Future<void> _initializeHive() async {
    try {
      await Hive.initFlutter();

      // Безопасная регистрация адаптеров
      if (!Hive.isAdapterRegistered(ActiveGiftModelAdapter().typeId)) {
        Hive.registerAdapter(ActiveGiftModelAdapter());
      }

      // Безопасное открытие боксов
      if (!Hive.isBoxOpen(activeGiftsBoxName)) {
        await Hive.openBox<ActiveGiftModel>(activeGiftsBoxName);
      }
    } catch (e) {
      debugPrint('❌ Hive initialization error: $e');
      rethrow;
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationServices.instance.initializeWithTokenListener();
      debugPrint('✅ Notifications initialized');
    } catch (e) {
      debugPrint('⚠️ Notifications initialization failed (non-critical): $e');
      // Don't stop app execution for notification errors
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Обёртка с белым фоном на самом верхнем уровне
    // Гарантирует белый фон при hot reload до инициализации MaterialApp
    return Container(
      color: Colors.white,
      child: ScreenUtilInit(
        designSize: const Size(390, 853),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          if (!_isInitialized && _initError == null) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: const KetroyStyleSplashScreen(),
              theme: AppTheme.lightThemeMode,
            );
          }

          // Показываем ошибку инициализации
          if (_initError != null) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: ErrorApp(error: _initError!),
              theme: AppTheme.lightThemeMode,
            );
          }

          return const KetroyApp();
        },
      ),
    );
  }
}

class KetroyApp extends StatelessWidget {
  const KetroyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LocalizationService>.value(
      value: serviceLocator<LocalizationService>(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => serviceLocator<AuthBloc>()),
          BlocProvider(
              create: (context) =>
                  serviceLocator<NewsBloc>()..add(const GetActualsFetch())),
          BlocProvider(create: (context) => serviceLocator<ProfileBloc>()),
          BlocProvider(create: (context) => serviceLocator<ShopBloc>()),
          BlocProvider(create: (context) => serviceLocator<ShopDetailBloc>()),
          BlocProvider(create: (context) => serviceLocator<CertificateBloc>()),
          BlocProvider(create: (context) => serviceLocator<DiscountBloc>()),
          BlocProvider(create: (context) => serviceLocator<GiftsBloc>()),
          BlocProvider(create: (context) => serviceLocator<PartnersBloc>()),
          BlocProvider(create: (context) => serviceLocator<NotificationBloc>()),
          BlocProvider(create: (context) => serviceLocator<AiBloc>()),
          BlocProvider(create: (context) => serviceLocator<BonusBloc>())
        ],
        child: MyApp(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final sharedService = serviceLocator<SharedPreferencesService>();

  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final locService = Provider.of<LocalizationService>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Ketroy App',
      theme: AppTheme.lightThemeMode,
      
      // Localization configuration
      locale: locService.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocalizationService.supportedLocales,
      localeResolutionCallback: LocalizationService.localeResolutionCallback,
      
      builder: (context, child) {
        return MediaQuery(
          // 🔒 фиксируем textScaleFactor (игнорируем системные настройки)
          data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0), boldText: false),
          child: child!,
        );
      },
      home: BlocConsumer<NewsBloc, NewsState>(
        listener: (context, state) {
          // Логируем изменения состояний для отладки
          debugPrint('NewsBloc state changed: ${state.status}');
          if (state.isFailure) {
            debugPrint('NewsBloc error: ${state.error}');
          }
        },
        builder: (context, state) {
          // Проверяем статус вместо содержимого списка
          if (state.isInitial || state.isLoading) {
            return const _BrandedLoadingScreen();
          } else if (state.isSuccess) {
            // Ищем приветственную группу (с is_welcome = true)
            if (state.actuals.isEmpty) {
              return const MainScreen();
            }
            
            // Ищем приветственную группу (ТОЛЬКО с is_welcome = true)
            // Если ни одна группа не помечена как приветственная - сразу MainScreen
            ActualsEntity? welcomeGroup;
            for (final actual in state.actuals) {
              if (actual.isWelcome) {
                welcomeGroup = actual;
                break;
              }
            }
            
            // Если нет приветственной группы или в ней нет историй - сразу MainScreen
            if (welcomeGroup == null || welcomeGroup.stories.isEmpty) {
              return const MainScreen();
            }
            
            // Показываем приветственные истории
            return StoriesScreen(
                stories: welcomeGroup.stories, firstLaunch: true);
          } else if (state.isFailure) {
            final l10n = AppLocalizations.of(context);
            return ErrorScreen(
              error: state.error ?? l10n?.unknownError ?? 'Unknown error',
              onRetry: () {
                context.read<NewsBloc>().add(const GetActualsFetch());
              },
            );
          } else {
            // Fallback для неизвестных состояний
            return const _BrandedLoadingScreen();
          }
        },
      ),
    );
  }
}

/// Оптимизированный брендовый экран загрузки с минимальным размером
/// Используется при hot reload и первоначальной загрузке данных
class _BrandedLoadingScreen extends StatelessWidget {
  const _BrandedLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Минимальный размер, не растягивается
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Брендовый лого (опционально)
            Image.asset(
              'images/logoK.png',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            // Компактный брендовый спиннер
            const Loader(size: 36, strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}
