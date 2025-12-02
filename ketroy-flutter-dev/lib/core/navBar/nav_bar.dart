import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:ketroy_app/core/common/widgets/auth_required_dialog.dart';
import 'package:ketroy_app/core/common/widgets/logout_confirm_dialog.dart';
import 'package:ketroy_app/core/common/widgets/back_button.dart';
import 'package:ketroy_app/core/constants/shop_contacts.dart';
import 'package:ketroy_app/core/model/nav_model.dart';
import 'package:ketroy_app/core/navBar/left_nav_bar.dart';
import 'package:ketroy_app/core/transitions/slide_over_page_route.dart';
import 'package:ketroy_app/core/transitions/auth_success_transition.dart';
import 'package:ketroy_app/features/active_gifts/presentation/view_model/all_gifts_view_model.dart';
import 'package:ketroy_app/features/active_gifts/presentation/widgets/active_page_body.dart';
import 'package:ketroy_app/features/ai/presentation/pages/ai_page.dart';
import 'package:ketroy_app/features/auth/domain/entities/user_entity.dart';
import 'package:ketroy_app/features/my_gifts/presentation/bloc/gifts_bloc.dart';
import 'package:ketroy_app/features/my_gifts/presentation/pages/my_gifts.dart';
import 'package:ketroy_app/features/news/presentation/pages/news_page.dart';
import 'package:ketroy_app/features/notification/presentation/pages/notification_page.dart';
import 'package:ketroy_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:ketroy_app/features/profile/presentation/pages/profile.dart';
import 'package:ketroy_app/features/profile/presentation/pages/qr_scanner_sheet.dart';
import 'package:ketroy_app/features/shop/presentation/pages/shop.dart';
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';
import 'package:ketroy_app/services/notification_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:ketroy_app/features/lottery/lottery_service.dart';

enum Options { search, upload, copy, exit }

class NavScreen extends StatefulWidget {
  final bool? fromGift;
  final bool withToken;
  final int initialTab;
  /// Показать анимацию приветствия после авторизации/регистрации
  final bool showWelcomeAnimation;
  /// Показать вкладку "Бонусы" на экране профиля
  final bool showBonusTab;
  
  const NavScreen({
    super.key,
    this.fromGift,
    this.withToken = true,
    this.initialTab = 0,
    this.showWelcomeAnimation = false,
    this.showBonusTab = false,
  });

  static final GlobalKey<NavScreenState> globalKey = GlobalKey();

  @override
  State<NavScreen> createState() => NavScreenState();
}

class NavScreenState extends State<NavScreen> with TickerProviderStateMixin {
  final homeNavKey = GlobalKey<NavigatorState>();
  final profileNavKey = GlobalKey<NavigatorState>();
  final shopNavKey = GlobalKey<NavigatorState>();
  final notifNavKey = GlobalKey<NavigatorState>();
  final partnersNavKey = GlobalKey<NavigatorState>();
  final activeGiftNavKey = GlobalKey<NavigatorState>();
  final aiNavKey = GlobalKey<NavigatorState>();

  // === Ключ для Scaffold (для открытия drawer из overlay) ===
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // === Ключ для анализа яркости фона (Anti-Chameleon) ===
  final _contentBoundaryKey = GlobalKey();

  // === Брендовый цвет ===
  static const Color brandColor = Color(0xFF3C4B1B); // Тёмно-зелёный Ketroy

  AuthUserEntity? user;
  Uri? whatsAppUrl;
  Uri? instaUrl;
  Uri? twoGisUrl;

  late int selectedTab;
  List<NavModel> items = [];
  String appBarTitle = '';
  var appBarHeight = AppBar().preferredSize.height;

  // ✅ Добавляем переменные для отслеживания состояния токена
  bool _hasToken = true; // По умолчанию считаем что токен есть
  bool _showProfileOverlay = false;

  // Состояние для главной страницы
  bool shouldExtendBodyBehindAppBar = true; // Начальное состояние
  bool isOnMainPage = true; // Отслеживаем, находимся ли на главной странице
  bool lastMainPageScrollState =
      true; // Сохраняем последнее состояние скролла главной страницы

  // Состояние для отслеживания наличия страниц в стеке навигации
  Map<int, bool> tabCanPop = {
    0: false,
    1: false,
    2: false,
    3: false,
    4: false,
    5: false,
  };

  int _activeGiftsCount = 0;
  int _notificationBadgeCount = 0;

  // Контроллер анимации для плавных переходов
  late AnimationController _transitionController;
  late Animation<double> _appBarAnimation;

  // Контроллер для анимации переключения страниц
  late AnimationController _pageTransitionController;

  // === Swipe to Notifications (Edge Swipe) ===
  double _swipeDelta = 0;
  bool _isSwipingToNotifications = false;
  static const double _swipeThreshold = 80; // Минимальный свайп для открытия
  static const double _edgeSwipeWidth =
      24; // Ширина зоны свайпа с правого края (узкая, незаметная)

  // Для визуального превью свайпа
  double _notificationPeekOffset = 0;

  // Анимация приветствия после авторизации
  bool _showWelcomeAnimation = false;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab;
    
    // Показываем анимацию приветствия если запрошено
    if (widget.showWelcomeAnimation) {
      _showWelcomeAnimation = true;
    }
    _loadUser();

    if (widget.withToken) {
      context.read<ProfileBloc>().add(GetProfileUserFetch());
    }

    _checkUserToken();

    _loadActiveGiftsCount();

    // Инициализация анимационного контроллера
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Анимация для AppBar (непрозрачность и позиция)
    _appBarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));

    // Инициализация контроллера для очень быстрого fade-перехода
    _pageTransitionController = AnimationController(
      duration: const Duration(
          milliseconds: 80), // Очень быстрый и незаметный переход
      vsync: this,
    )..value = 1.0; // Начинаем с полной непрозрачности

    items = [
      NavModel(
          page: NewsPage(onScrollModeChanged: _handleMainPageScrollModeChange),
          navKey: homeNavKey),
      NavModel(page: ProfilePage(showBonusTab: widget.showBonusTab), navKey: profileNavKey),
      NavModel(
          page: const ShopPage(
            pop: false,
          ),
          navKey: shopNavKey),
      NavModel(page: const AiPage(), navKey: aiNavKey),
      // NavModel(page: PartnersPage(), navKey: partnersNavKey),
      NavModel(page: const MyGifts(showBackButton: false), navKey: activeGiftNavKey),
    ];
    if (selectedTab < 0 || selectedTab >= items.length) {
      selectedTab = 0;
    }
    _loadNotificationBadgeCount();
    
    // После построения экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Обрабатываем pending push-уведомление (если приложение было закрыто)
      NotificationServices.instance.processPendingInitialMessage();
      
      // Проверяем активную лотерею
      if (widget.withToken) {
        _checkForActiveLottery();
      }
    });
  }

  /// Проверка активной лотереи при входе в приложение
  Future<void> _checkForActiveLottery() async {
    if (!mounted) return;
    
    // Небольшая задержка чтобы экран успел полностью отрисоваться
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted) return;
    
    LotteryService().checkAndShowLotteryModal(context);
  }

  void _loadNotificationBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final badgeCount = prefs.getInt('badge_count') ?? 0;

      if (mounted && _notificationBadgeCount != badgeCount) {
        setState(() {
          _notificationBadgeCount = badgeCount;
        });
      }
    } catch (e) {
      debugPrint('Error loading notification badge count: $e');
    }
  }

  void _loadActiveGiftsCount() {
    try {
      // Создаем временный экземпляр AllGiftsViewModel для получения данных
      final tempViewModel = AllGiftsViewModel();
      tempViewModel.initialize(); // Вызываем без await

      if (mounted) {
        setState(() {
          _activeGiftsCount = tempViewModel.items.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading active gifts count: $e');
    }
  }

  void updateActiveGiftsCount(int count) {
    if (mounted && _activeGiftsCount != count) {
      setState(() {
        _activeGiftsCount = count;
      });
    }
  }

  void updateNotificationBadge(int count) {
    if (mounted && _notificationBadgeCount != count) {
      setState(() {
        _notificationBadgeCount = count;
      });
    }
  }

  // ✅ Обновите метод updateNavState для перезагрузки количества
  void updateNavState() {
    if (mounted) {
      setState(() {
        ActivePageBody.globalKey.currentState?.refresh();
      });
      _loadActiveGiftsCount(); // Перезагружаем количество подарков
    }
  }

  Future<void> _loadUser() async {
    try {
      final userData = await UserDataManager.getUser();
      setState(() {
        user = userData;
      });
      // Загружаем магазин для соцсетей после получения данных пользователя
      _loadCityShopUrls();
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  void _loadCityShopUrls() {
    // Получаем магазин из ProfileBloc
    final profileState = context.read<ProfileBloc>().state;
    final cityShop = profileState.cityShop;

    if (cityShop != null) {
      // Используем данные из магазина города пользователя
      setState(() {
        if (cityShop.whatsApp.isNotEmpty) {
          whatsAppUrl = Uri.tryParse('https://wa.me/${cityShop.whatsApp}');
        } else {
          whatsAppUrl = WhatsAppContacts.almatyWhatsapp;
        }
        
        if (cityShop.instagram.isNotEmpty) {
          instaUrl = Uri.tryParse(cityShop.instagram);
        } else {
          instaUrl = InstaContacts.almatyInsta;
        }
        
        if (cityShop.twoGisAddress.isNotEmpty) {
          twoGisUrl = Uri.tryParse(cityShop.twoGisAddress);
        } else {
          twoGisUrl = Uri.parse('https://go.2gis.com/ketroy');
        }
      });
    } else {
      // Если магазин ещё не загружен - используем fallback на статические ссылки
      _updateUrlsFromCity();
      // Загружаем магазин через ProfileBloc
      context.read<ProfileBloc>().add(LoadCityShop());
    }
  }

  void _updateUrlsFromCity() {
    if (user?.city == null) {
      whatsAppUrl = WhatsAppContacts.almatyWhatsapp;
      instaUrl = InstaContacts.almatyInsta;
      twoGisUrl = Uri.parse('https://go.2gis.com/ketroy');
      return;
    }

    switch (user!.city) {
      case 'Алматы':
        whatsAppUrl = WhatsAppContacts.almatyWhatsapp;
        instaUrl = InstaContacts.almatyInsta;
        break;
      case 'Астана':
        whatsAppUrl = WhatsAppContacts.astanaWhatsapp;
        instaUrl = InstaContacts.astanaInsta;
        break;
      case 'Актау':
        whatsAppUrl = WhatsAppContacts.aqtauWhatsapp;
        instaUrl = InstaContacts.aqtauInsta;
        break;
      case 'Шымкент':
        whatsAppUrl = WhatsAppContacts.shymkentWhatsapp;
        instaUrl = InstaContacts.shymkentInsta;
        break;
      default:
        whatsAppUrl = WhatsAppContacts.almatyWhatsapp;
        instaUrl = InstaContacts.almatyInsta;
    }
    twoGisUrl = Uri.parse('https://go.2gis.com/ketroy');
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _pageTransitionController.dispose();
    super.dispose();
  }

  // ✅ Метод для проверки токена пользователя
  Future<void> _checkUserToken() async {
    try {
      final hasToken = widget.withToken;

      if (mounted && _hasToken != hasToken) {
        setState(() {
          _hasToken = hasToken;
        });
        _updateOverlayVisibility();
      }
    } catch (e) {
      // Если ошибка получения данных - считаем что токена нет
      if (mounted && _hasToken != false) {
        setState(() {
          _hasToken = false;
        });
        _updateOverlayVisibility();
      }
    }
  }

  // Обработчик изменения режима скролла главной страницы
  void _handleMainPageScrollModeChange(bool shouldExtend) {
    if (selectedTab == 0 && isOnMainPage) {
      // Сохраняем состояние для будущих возвратов
      lastMainPageScrollState = shouldExtend;
      _updateExtendBodyBehindAppBar(shouldExtend);
    }
  }

  // Универсальный метод для обновления состояния AppBar
  void _updateExtendBodyBehindAppBar(bool shouldExtend) {
    if (shouldExtend != shouldExtendBodyBehindAppBar) {
      setState(() {
        shouldExtendBodyBehindAppBar = shouldExtend;
      });

      // Анимируем переход
      if (shouldExtend) {
        _transitionController.reverse(); // AppBar скрывается
      } else {
        _transitionController.forward(); // AppBar появляется
      }

      debugPrint('NavScreen: extendBodyBehindAppBar changed to $shouldExtend');
    }
  }

  void _handleNavigationChanged() {
    // Обновляем состояние для текущей вкладки
    final currentCanPop =
        items[selectedTab].navKey.currentState?.canPop() ?? false;

    setState(() {
      tabCanPop[selectedTab] = currentCanPop;
    });

    if (selectedTab == 0) {
      // Проверяем, находимся ли на главной странице в главной вкладке
      final newIsOnMainPage = !currentCanPop;

      if (newIsOnMainPage != isOnMainPage) {
        setState(() {
          isOnMainPage = newIsOnMainPage;
        });

        // Если перешли на другой экран внутри главной вкладки
        if (!isOnMainPage) {
          // Сохраняем текущее состояние перед переходом
          lastMainPageScrollState = shouldExtendBodyBehindAppBar;
          // Показываем AppBar (extendBodyBehindAppBar = false)
          _updateExtendBodyBehindAppBar(false);
        } else {
          // Вернулись на главную страницу - восстанавливаем предыдущее состояние
          _updateExtendBodyBehindAppBar(lastMainPageScrollState);
          debugPrint(
              'NavScreen: Restored main page AppBar state to $lastMainPageScrollState');
        }

        debugPrint('NavScreen: isOnMainPage changed to $isOnMainPage');
      }
    } else {
      // Для других вкладок всегда показываем AppBar
      if (isOnMainPage) {
        setState(() {
          isOnMainPage = false;
        });
      }
      // ДОБАВЬ ЭТО: Когда переключаемся обратно на главную вкладку
      // проверяем нужно ли восстановить состояние главной страницы
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Если пришли из подарка — открываем Gifts внутри вкладки "Профиль"
    if (widget.fromGift == true) {
      setState(() {
        selectedTab = 1; // вкладка Профиль
      });

      // Делаем это после первой отрисовки
      WidgetsBinding.instance.addPostFrameCallback((_) {
        profileNavKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const MyGifts()),
        );
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotificationBadgeCount();
    });
  }

  void _openDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Drawer',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, anim1, anim2) {
        return BlurLeftNavBar(
          pageIndex: selectedTab,
          onTap: (index) {
            setState(() {
              selectedTab = index;
            });
          },
          whatsAppUrl: whatsAppUrl,
          instaUrl: instaUrl,
          twoGisUrl: twoGisUrl,
          city: user?.city,
        );
      },
    );
  }

  void _onTabChanged(int newIndex) async {
    final oldIndex = selectedTab;
    final l10n = AppLocalizations.of(context);

    // ✅ Проверяем авторизацию при переходе на вкладку "Мои подарки" (индекс 4)
    if (newIndex == 4 && !_hasToken) {
      AuthRequiredDialog.show(
        context,
        title: l10n?.authRequired ?? 'Authorization Required',
        message: l10n?.authRequiredMessage ?? 'To access information about yourself, discounts, gifts and other bonuses — you need to register!',
      );
      return; // Не переключаемся на вкладку
    }

    // ✅ Показываем навбар при переключении табов (если он был скрыт)
    if (!_isNavBarVisible) {
      setNavBarVisibility(true);
    }

    // Запускаем анимацию исчезновения текущей страницы
    await _pageTransitionController.reverse();

    setState(() {
      selectedTab = newIndex;
    });

    // Запускаем анимацию появления новой страницы
    await _pageTransitionController.forward();

    if (!mounted) {
      return;
    }

    // ✅ Проверяем токен при переходе на вкладку профиля
    if (newIndex == 1) {
      _checkUserToken();
    }

    if (newIndex == 4) {
      context.read<GiftsBloc>().add(GetGiftsListFetch());
    }

    // Обновляем overlay при смене вкладки
    _updateOverlayVisibility();

    // Если переключились на главную вкладку (0) с другой вкладки
    if (newIndex == 0 && oldIndex != 0) {
      // Проверяем состояние главной вкладки
      final mainTabCanPop = items[0].navKey.currentState?.canPop() ?? false;
      final newIsOnMainPage = !mainTabCanPop;

      setState(() {
        isOnMainPage = newIsOnMainPage;
      });

      if (isOnMainPage) {
        // Восстанавливаем состояние скролла главной страницы
        _updateExtendBodyBehindAppBar(lastMainPageScrollState);
      } else {
        // На внутренней странице главной вкладки
        _updateExtendBodyBehindAppBar(false);
      }

      debugPrint(
          'NavScreen: Switched to main tab, isOnMainPage: $isOnMainPage');
    }
  }

  // ✅ Добавьте этот метод
  void switchToTab(int tabIndex, {bool popToFirst = false}) {
    if (mounted && tabIndex >= 0 && tabIndex < items.length) {
      if (popToFirst) {
        items[tabIndex].navKey.currentState?.popUntil((route) => route.isFirst);
      }
      _onTabChanged(tabIndex);
    }
  }

  // === Управление видимостью навбара ===
  bool _isNavBarVisible = true;
  
  void setNavBarVisibility(bool visible) {
    if (mounted && _isNavBarVisible != visible) {
      setState(() {
        _isNavBarVisible = visible;
      });
    }
  }

  // === Открытие QR-сканера ===
  void _openQrScanner() async {
    final l10n = AppLocalizations.of(context);
    // Проверяем авторизацию
    if (!_hasToken) {
      AuthRequiredDialog.show(
        context,
        title: l10n?.authRequired ?? 'Authorization Required',
        message: l10n?.authRequiredQr ?? 'To scan QR code and receive bonuses, you need to log in.',
      );
      return;
    }

    // Открываем QR-сканер как нижнюю шторку
    final result = await showQrScannerSheet(context);

    // Обновляем данные после сканирования
    if (result == true && mounted) {
      context.read<ProfileBloc>().add(GetDiscountFetch());
    }
  }

  // === Открытие уведомлений с Slide Over анимацией ===
  void _openNotificationsWithSlideOver() {
    final l10n = AppLocalizations.of(context);
    // Проверяем авторизацию
    if (!_hasToken) {
      AuthRequiredDialog.show(
        context,
        title: l10n?.authRequired ?? 'Authorization Required',
        message: l10n?.authRequiredNotifications ?? 'To view notifications, you need to log in.',
      );
      return;
    }
    
    Navigator.of(context)
        .push(
      SlideOverPageRoute(page: const NotificationPage()),
    )
        .then((_) {
      _loadNotificationBadgeCount();
    });
  }

  // === Edge Swipe — свайп только с правого края экрана ===
  // Не конфликтует с каруселью, фильтрами и другими горизонтальными свайпами

  void _handleEdgeSwipeStart(DragStartDetails details) {
    if (selectedTab == 1) return; // Не на профиле

    _isSwipingToNotifications = true;
    _swipeDelta = 0;
  }

  void _handleEdgeSwipeUpdate(DragUpdateDetails details) {
    if (!_isSwipingToNotifications) return;

    _swipeDelta += details.primaryDelta ?? 0;

    // Визуальный превью — показываем край экрана уведомлений
    final peekAmount = (-_swipeDelta).clamp(0.0, 150.0);
    if (peekAmount != _notificationPeekOffset) {
      setState(() {
        _notificationPeekOffset = peekAmount;
      });
    }
  }

  void _handleEdgeSwipeEnd(DragEndDetails details) {
    if (!_isSwipingToNotifications) {
      _resetSwipeState();
      return;
    }

    final velocity = details.primaryVelocity ?? 0;

    // Открываем уведомления если:
    // 1. Свайпнули достаточно влево (отрицательный delta)
    // 2. ИЛИ скорость свайпа влево достаточная
    // 3. ИЛИ показали достаточный превью
    if (_swipeDelta < -_swipeThreshold ||
        velocity < -800 ||
        _notificationPeekOffset > 100) {
      _openNotificationsWithSlideOver();
    }

    _resetSwipeState();
  }

  void _resetSwipeState() {
    if (_notificationPeekOffset != 0) {
      setState(() {
        _notificationPeekOffset = 0;
      });
    }
    _isSwipingToNotifications = false;
    _swipeDelta = 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentNavigator = items[selectedTab].navKey.currentState;
    final canInnerNavigatorPop = currentNavigator?.canPop() ?? false;

    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) => previous.cityShop != current.cityShop,
      listener: (context, state) {
        // Обновляем URL соцсетей когда cityShop загрузился
        if (state.cityShop != null) {
          _loadCityShopUrls();
        }
      },
      child: PopScope(
      canPop: !canInnerNavigatorPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        final navigatorState = items[selectedTab].navKey.currentState;
        if (navigatorState?.canPop() ?? false) {
          navigatorState!.pop();
        }
      },
      child: AnimatedBuilder(
          animation: _transitionController,
          builder: (context, child) {
            // Определяем, показывать ли sticky header
            // Профиль (1), AI страница (3) и Подарки (4) имеют свои собственные headers
            final showStickyHeader = selectedTab != 1 &&
                selectedTab != 3 &&
                selectedTab != 4 &&
                (selectedTab != 0 ||
                    !shouldExtendBodyBehindAppBar ||
                    !isOnMainPage);

            return Stack(
              children: [
                // === СЛОЙ 1: Scaffold с контентом ===
                Scaffold(
                  key: _scaffoldKey,
                  drawerEnableOpenDragGesture: false,
                  extendBodyBehindAppBar:
                      true, // Всегда true — AppBar как overlay
                  body: Stack(
                    children: [
                      // === Контент страниц ===
                      RepaintBoundary(
                        key: _contentBoundaryKey,
                        child: FadeTransition(
                          opacity: _pageTransitionController,
                          child: IndexedStack(
                            index: selectedTab,
                            children: items.map((page) {
                              return Navigator(
                                key: page.navKey,
                                observers: [
                                  NavObserver(_handleNavigationChanged)
                                ],
                                onGenerateInitialRoutes:
                                    (navigator, initialRoute) {
                                  return [
                                    MaterialPageRoute(
                                        builder: (context) => page.page)
                                  ];
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // === Liquid Glass иконка уведомлений (только на витрине без sticky header) ===
                      if (selectedTab == 0 &&
                          isOnMainPage &&
                          shouldExtendBodyBehindAppBar)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8.h,
                          right: 16.w,
                          child: _buildLiquidGlassNotificationButton(),
                        ),

                      // === NavBar снизу (с анимацией скрытия) ===
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        left: 0,
                        right: 0,
                        bottom: _isNavBarVisible ? 0 : -100,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _isNavBarVisible ? 1.0 : 0.0,
                          child: NavBar(
                            pageIndex: selectedTab,
                            onTap: (index) {
                              if (index == selectedTab) {
                                items[index]
                                    .navKey
                                    .currentState
                                    ?.popUntil((route) {
                                  return route.isFirst;
                                });
                              } else {
                                _onTabChanged(index);
                              }
                            },
                            onQrTap: _openQrScanner,
                            activeGiftsCount: _activeGiftsCount,
                            contentKey: _contentBoundaryKey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ), // закрываем Scaffold

                // === Edge Swipe Zone — зона свайпа справа (не мешает карусели и фильтрам) ===
                if (selectedTab != 1) // Не на профиле
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: _edgeSwipeWidth,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragStart: _handleEdgeSwipeStart,
                      onHorizontalDragUpdate: _handleEdgeSwipeUpdate,
                      onHorizontalDragEnd: _handleEdgeSwipeEnd,
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),

                // === Затемнение при свайпе ===
                if (_notificationPeekOffset > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(
                          alpha:
                              (_notificationPeekOffset / 300).clamp(0.0, 0.3),
                        ),
                      ),
                    ),
                  ),

                // === Превью экрана уведомлений при свайпе ===
                if (_notificationPeekOffset > 0)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: _notificationPeekOffset,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.r),
                          bottomLeft: Radius.circular(20.r),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 25,
                            spreadRadius: 5,
                            offset: const Offset(-8, 0),
                          ),
                        ],
                      ),
                      child: Opacity(
                        opacity: (_notificationPeekOffset / 80).clamp(0.0, 1.0),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: Colors.grey[500],
                          size: 28.sp,
                        ),
                      ),
                    ),
                  ),

                // === СЛОЙ 2: Sticky Header (overlay сверху — без "прыжка") ===
                if (showStickyHeader)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildOverlayAppBar(context),
                  ),

                if (_showProfileOverlay) _buildLoginPrompt(),
                
                // === СЛОЙ 3: Анимация приветствия после авторизации ===
                if (_showWelcomeAnimation)
                  WelcomeAnimationOverlay(
                    onComplete: () {
                      if (mounted) {
                        setState(() {
                          _showWelcomeAnimation = false;
                        });
                      }
                    },
                  ),
              ],
            );
          }),
      ),
    );
  }

  /// Liquid Glass кнопка уведомлений для витрины с Anti-Chameleon
  Widget _buildLiquidGlassNotificationButton() {
    return _LiquidGlassNotificationButton(
      notificationCount: _hasToken ? _notificationBadgeCount : 0, // Скрываем badge если не авторизован
      contentKey: _contentBoundaryKey,
      onTap: _openNotificationsWithSlideOver, // Slide Over анимация (проверка авторизации внутри)
    );
  }

  /// Overlay AppBar (появляется сверху как слой, не сдвигая контент)
  Widget _buildOverlayAppBar(BuildContext context) {
    final canPop = tabCanPop[selectedTab] ?? false;

    return AnimatedBuilder(
      animation: _appBarAnimation,
      builder: (context, child) {
        // Для главной страницы анимируем появление
        final opacity = selectedTab == 0 ? _appBarAnimation.value : 1.0;
        final translateY = selectedTab == 0
            ? -kToolbarHeight * (1 - _appBarAnimation.value)
            : 0.0;

        return Transform.translate(
          offset: Offset(0, translateY),
          child: Opacity(
            opacity: opacity,
            child: Material(
              color: Colors.white,
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05 * opacity),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: kToolbarHeight,
                    child: Row(
                      children: [
                        // Leading: KETROY или Back button
                        if (canPop)
                          CustomBackButton(onTap: () {
                            items[selectedTab].navKey.currentState?.pop();
                          })
                        else
                          InkWell(
                            onTap: _openDrawer,
                            borderRadius: BorderRadius.circular(8.r),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 8.h),
                              child: Text(
                                'KETROY',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w700,
                                  color: brandColor, // Брендовый зелёный
                                  letterSpacing: 3.0,
                                ),
                              ),
                            ),
                          ),

                        // Spacer
                        const Spacer(),

                        // Actions
                        if (selectedTab == 1)
                          _buildProfileActions()
                        else
                          _buildNotificationAction(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationAction() {
    // Показываем badge только для авторизованных пользователей
    final showBadge = _hasToken && _notificationBadgeCount > 0;
    
    return GestureDetector(
      onTap: _openNotificationsWithSlideOver, // Slide Over анимация
      child: Padding(
        padding: EdgeInsets.only(right: 16.w),
        child: SizedBox(
          width: 30.w,
          child: Stack(
            children: [
              SvgPicture.asset(
                'images/notif2.svg',
                colorFilter: const ColorFilter.mode(
                  brandColor, // Брендовый зелёный цвет
                  BlendMode.srcIn,
                ),
              ),
              if (showBadge)
                Positioned(
                  right: 4,
                  top: 0,
                  child: Container(
                    width: 16.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFAD1A1A),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
                        _notificationBadgeCount > 9
                            ? '9+'
                            : '$_notificationBadgeCount',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileActions() {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      padding: const EdgeInsets.all(0),
      color: Colors.black,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      offset: Offset(-30, appBarHeight),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          padding: EdgeInsets.zero,
          value: 'logout',
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 27.w, vertical: 20.h),
            width: 273.w,
            child: Row(
              children: [
                Text(l10n?.logoutFromAccount ?? 'Log Out',
                    style: TextStyle(color: Colors.white, fontSize: 17.sp)),
              ],
            ),
          ),
        ),
        PopupMenuItem<String>(
          padding: EdgeInsets.zero,
          value: 'delete',
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 27.w, vertical: 20.h),
            width: 273.w,
            child: Row(
              children: [
                Text(l10n?.deleteAccount ?? 'Delete Account',
                    style: TextStyle(color: Colors.red, fontSize: 17.sp)),
              ],
            ),
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'logout':
            onLogOutPressed();
            break;
          case 'delete':
            onDeleteAccount();
            break;
        }
      },
    );
  }

  // ✅ Метод для обновления видимости overlay
  void _updateOverlayVisibility() {
    final shouldShow = !_hasToken && selectedTab == 1 ||
        !_hasToken &&
            selectedTab == 3; // Нет токена И на вкладке профиля (индекс 1)

    if (_showProfileOverlay != shouldShow) {
      setState(() {
        _showProfileOverlay = shouldShow;
      });
    }
  }

  Widget _buildLoginPrompt() {
    final l10n = AppLocalizations.of(context);
    return AuthRequiredDialog(
      title: l10n?.authRequired ?? 'Authorization Required',
      message: l10n?.authRequiredMessage ?? 'To access information about yourself, discounts, gifts and other bonuses — you need to register!',
      onLoginPressed: () {
        setState(() {
          _showProfileOverlay = false;
        });
      },
      onAfterLogin: () {
        _checkUserToken();
      },
      onCancel: () {
        setState(() {
          _showProfileOverlay = false;
          selectedTab = 0; // Переходим на главную
        });
      },
    );
  }

  Future<bool> onLogOutPressed() async {
    final confirmed = await LogoutConfirmDialog.show(context);
    if (confirmed && mounted) {
      context.read<ProfileBloc>().add(LogOutFetch());
    }
    return confirmed;
  }

  Future<bool> onDeleteAccount() async {
    final l10n = AppLocalizations.of(context);
    return (await showDialog(
          context: context,
          builder: (dialogContext) {
            AlertDialog alert = AlertDialog(
              backgroundColor: Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    textAlign: TextAlign.center,
                    l10n?.deleteAccountConfirm ?? 'Delete account?',
                    style:
                        TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 8.h,
                  ),
                  Text(
                      textAlign: TextAlign.center,
                      l10n?.deleteAccountWarning ?? 'By deleting your account, you lose access to all personal data, including bonuses and special offers. Re-registration will remain available at any time.'),
                  SizedBox(
                    height: 13.h,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(7.r)),
                    child: AppButton(
                        title: l10n?.delete ?? 'Delete',
                        onPressed: () {
                          context.read<ProfileBloc>().add(DeleteUserFetch());
                        },
                        backgroundColor: Colors.white),
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(7.r)),
                    child: AppButton(
                        title: l10n?.cancel ?? 'Cancel',
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                        backgroundColor: Colors.white),
                  ),
                ],
              ),
              // actions: [cancelButton, logOutButton],
            );
            return alert;
          },
        )) ??
        false;
  }
}

// ============================================================================
// LIQUID GLASS PILL NAV BAR (Apple Style - Smart Contrast / Anti-Chameleon)
// Автоматически адаптирует цвета иконок на основе яркости фона
// ============================================================================

class NavBar extends StatefulWidget {
  final int pageIndex;
  final Function(int) onTap;
  final VoidCallback? onQrTap; // Callback для QR-кнопки
  final int activeGiftsCount;
  final GlobalKey? contentKey; // Ключ для захвата контента

  const NavBar({
    super.key,
    required this.pageIndex,
    required this.onTap,
    this.onQrTap,
    this.activeGiftsCount = 0,
    this.contentKey,
  });

  // === ЦВЕТА ДЛЯ СВЕТЛОГО ФОНА (тёмные иконки) ===
  static const Color activeDarkColor = Color(0xFF2D3A14); // Тёмно-зелёный
  static const Color inactiveDarkColor = Color(0xFF3D3D3D); // Тёмно-серый

  // === ЦВЕТА ДЛЯ ТЁМНОГО ФОНА (светлые иконки) ===
  static const Color activeLightColor = Color(0xFF9FBF5A); // Светло-зелёный
  static const Color inactiveLightColor = Color(0xFFE8E8E8); // Светло-серый

  // === КОНСТАНТЫ ДЛЯ РАСЧЁТА ОТСТУПОВ ===
  static const double navBarHeight = 72;
  static const double bottomMargin = 4;
  static const double horizontalMargin = 20;
  
  /// Минимальный отступ снизу для устройств без системной навигации
  /// (жесты без видимой панели или очень маленький padding)
  static const double minBottomSafeArea = 16;

  /// Порог яркости для переключения цветовой схемы (0-1)
  /// < 0.5 = тёмный фон, >= 0.5 = светлый фон
  static const double luminanceThreshold = 0.5;

  static double getBottomPadding(BuildContext context) {
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;
    // Гарантируем минимальный отступ на всех устройствах
    final bottomSafeArea = systemBottomPadding < minBottomSafeArea 
        ? minBottomSafeArea 
        : systemBottomPadding;
    return navBarHeight.h + bottomMargin.h + bottomSafeArea + 8.h;
  }

  static EdgeInsets getPagePadding(BuildContext context) {
    return EdgeInsets.only(bottom: getBottomPadding(context));
  }

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  bool _isDarkBackground = false; // По умолчанию считаем фон светлым
  Timer? _luminanceTimer;

  @override
  void initState() {
    super.initState();
    // Запускаем периодический анализ яркости
    _startLuminanceAnalysis();
  }

  @override
  void dispose() {
    _luminanceTimer?.cancel();
    super.dispose();
  }

  void _startLuminanceAnalysis() {
    // Анализируем каждые 200ms для плавной реакции
    _luminanceTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _analyzeLuminance();
    });
    // Первый анализ сразу
    WidgetsBinding.instance.addPostFrameCallback((_) => _analyzeLuminance());
  }

  Future<void> _analyzeLuminance() async {
    if (!mounted || widget.contentKey == null) return;

    try {
      final boundary = widget.contentKey!.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null || !boundary.hasSize) return;
      
      // На iOS не проверяем debugNeedsPaint - может блокировать анализ
      // На Android оставляем проверку для оптимизации
      if (!Platform.isIOS && boundary.debugNeedsPaint) return;

      // iOS требует более высокий pixelRatio для корректного захвата
      final pixelRatio = Platform.isIOS ? 0.2 : 0.1;
      
      // Захватываем изображение области под навбаром
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData == null) {
        image.dispose();
        return;
      }

      // Анализируем только нижнюю часть изображения (где NavBar)
      final width = image.width;
      final height = image.height;
      final navBarAreaHeight = (height * 0.15).toInt(); // Нижние 15% экрана

      double totalLuminance = 0;
      int pixelCount = 0;

      // Сканируем пиксели в области NavBar
      for (int y = height - navBarAreaHeight; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final offset = (y * width + x) * 4;
          if (offset + 3 < byteData.lengthInBytes) {
            final r = byteData.getUint8(offset);
            final g = byteData.getUint8(offset + 1);
            final b = byteData.getUint8(offset + 2);

            // Вычисляем яркость по формуле ITU-R BT.709
            final luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
            totalLuminance += luminance;
            pixelCount++;
          }
        }
      }

      image.dispose();
      
      if (pixelCount == 0) return;

      final avgLuminance = totalLuminance / pixelCount;
      final isDark = avgLuminance < NavBar.luminanceThreshold;

      // Обновляем состояние только если изменилось
      if (mounted && isDark != _isDarkBackground) {
        setState(() {
          _isDarkBackground = isDark;
        });
      }
    } catch (e) {
      // Логируем ошибки для диагностики
      debugPrint('NavBar luminance analysis error: $e');
    }
  }

  // Получаем текущие цвета на основе яркости фона
  Color get _activeColor =>
      _isDarkBackground ? NavBar.activeLightColor : NavBar.activeDarkColor;

  Color get _inactiveColor =>
      _isDarkBackground ? NavBar.inactiveLightColor : NavBar.inactiveDarkColor;

  // Зелёный цвет для QR-кнопки
  static const Color _qrButtonColor = Color(0xFF3C4B1B);

  @override
  Widget build(BuildContext context) {
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;
    // Гарантируем минимальный отступ на всех устройствах
    final bottomPadding = systemBottomPadding < NavBar.minBottomSafeArea 
        ? NavBar.minBottomSafeArea 
        : systemBottomPadding;
    final navBarWidth =
        MediaQuery.of(context).size.width - (NavBar.horizontalMargin * 2).w;

    return Container(
      margin: EdgeInsets.fromLTRB(
        NavBar.horizontalMargin.w,
        0,
        NavBar.horizontalMargin.w,
        bottomPadding + NavBar.bottomMargin.h,
      ),
      height: NavBar.navBarHeight.h,
      child: LiquidGlass.withOwnLayer(
        settings: AppLiquidGlassSettings.navBar,
        shape: LiquidRoundedSuperellipse(borderRadius: 36.r),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // === Glow под активным элементом (5 позиций, без центральной) ===
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              left: _getGlowPosition(navBarWidth),
              top: 12.h,
              bottom: 12.h,
              width: navBarWidth / 5,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 45.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: _activeColor.withValues(alpha: 0.25),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),

                // === Иконки навигации (5 элементов) ===
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        'images/nav_logo.svg',
                        l10n?.showcase ?? 'Showcase',
                        widget.pageIndex == 0,
                        false,
                        null,
                        () => widget.onTap(0),
                      ),
                      _buildNavItem(
                        'images/chatBot.svg',
                        l10n?.ai ?? 'AI',
                        widget.pageIndex == 3,
                        false,
                        null,
                        () => widget.onTap(3),
                      ),
                      // Центральная QR-кнопка (placeholder для правильного spacing)
                      _buildQrButton(),
                      _buildNavItem(
                        'images/gift.svg',
                        l10n?.giftsTab ?? 'Gifts',
                        widget.pageIndex == 4,
                        widget.activeGiftsCount > 0,
                        widget.activeGiftsCount,
                        () => widget.onTap(4),
                      ),
                      _buildNavItem(
                        'images/profile2.svg',
                        l10n?.profile ?? 'Profile',
                        widget.pageIndex == 1,
                        false,
                        null,
                        () => widget.onTap(1),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  double _getGlowPosition(double navBarWidth) {
    final itemWidth = navBarWidth / 5;
    switch (widget.pageIndex) {
      case 0:
        return itemWidth * 0; // Витрина
      case 3:
        return itemWidth * 1; // AI
      case 4:
        return itemWidth * 3; // Подарки
      case 1:
        return itemWidth * 4; // Профиль
      default:
        return itemWidth * 0;
    }
  }

  // Особая QR-кнопка с зелёной плашкой
  Widget _buildQrButton() {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onQrTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF5A6F2B), // Светлее
                  _qrButtonColor,    // Основной зелёный
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _qrButtonColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 26.w,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String image,
    String title,
    bool selected,
    bool showBadge,
    int? badgeCount,
    VoidCallback onTap,
  ) {
    final iconColor = selected ? _activeColor : _inactiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: selected
                          ? _activeColor.withValues(alpha: 0.15)
                          : Colors.transparent,
                    ),
                    child: SvgPicture.asset(
                      image,
                      width: 22.w,
                      colorFilter: ColorFilter.mode(
                        iconColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  // Badge
                  if (showBadge && badgeCount != null && badgeCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 16.w,
                        height: 16.h,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFAD1A1A),
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: iconColor,
                  fontSize: 10.sp,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(title),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет-обёртка для страниц с NavBar — автоматически добавляет padding снизу
class NavBarSafeArea extends StatelessWidget {
  final Widget child;
  final bool addPadding;

  const NavBarSafeArea({
    super.key,
    required this.child,
    this.addPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!addPadding) return child;

    return Padding(
      padding: NavBar.getPagePadding(context),
      child: child,
    );
  }
}

/// Навигационный Observer, вызывающий setState() при изменениях маршрута
class NavObserver extends NavigatorObserver {
  final VoidCallback onNavigationChanged;

  NavObserver(this.onNavigationChanged);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onNavigationChanged();
    });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onNavigationChanged();
    });
  }
}

// ============================================================================
// LIQUID GLASS NOTIFICATION BUTTON с Anti-Chameleon
// ============================================================================

class _LiquidGlassNotificationButton extends StatefulWidget {
  final int notificationCount;
  final GlobalKey? contentKey;
  final VoidCallback onTap;

  const _LiquidGlassNotificationButton({
    required this.notificationCount,
    required this.onTap,
    this.contentKey,
  });

  @override
  State<_LiquidGlassNotificationButton> createState() =>
      _LiquidGlassNotificationButtonState();
}

class _LiquidGlassNotificationButtonState
    extends State<_LiquidGlassNotificationButton> {
  bool _isDarkBackground = false;
  Timer? _luminanceTimer;

  // Цвета для светлого фона (тёмная иконка)
  static const Color _darkIconColor = Color(0xFF2D2D2D);

  // Цвета для тёмного фона (светлая иконка)
  static const Color _lightIconColor = Color(0xFFE8E8E8);

  @override
  void initState() {
    super.initState();
    _startLuminanceAnalysis();
  }

  @override
  void dispose() {
    _luminanceTimer?.cancel();
    super.dispose();
  }

  void _startLuminanceAnalysis() {
    _luminanceTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _analyzeLuminance();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _analyzeLuminance());
  }

  Future<void> _analyzeLuminance() async {
    if (!mounted || widget.contentKey == null) return;

    try {
      final boundary = widget.contentKey!.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null || !boundary.hasSize) return;
      
      // На iOS не проверяем debugNeedsPaint - может блокировать анализ
      if (!Platform.isIOS && boundary.debugNeedsPaint) return;

      // iOS требует более высокий pixelRatio для корректного захвата
      final pixelRatio = Platform.isIOS ? 0.2 : 0.1;
      
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData == null) {
        image.dispose();
        return;
      }

      final width = image.width;
      final height = image.height;

      // Анализируем верхний правый угол (где находится кнопка)
      final areaWidth = (width * 0.2).toInt();
      final areaHeight = (height * 0.1).toInt();

      double totalLuminance = 0;
      int pixelCount = 0;

      for (int y = 0; y < areaHeight; y++) {
        for (int x = width - areaWidth; x < width; x++) {
          final offset = (y * width + x) * 4;
          if (offset + 3 < byteData.lengthInBytes) {
            final r = byteData.getUint8(offset);
            final g = byteData.getUint8(offset + 1);
            final b = byteData.getUint8(offset + 2);

            final luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
            totalLuminance += luminance;
            pixelCount++;
          }
        }
      }

      image.dispose();
      
      if (pixelCount == 0) return;

      final avgLuminance = totalLuminance / pixelCount;
      final isDark = avgLuminance < 0.5;

      if (mounted && isDark != _isDarkBackground) {
        setState(() {
          _isDarkBackground = isDark;
        });
      }
    } catch (e) {
      debugPrint('Notification button luminance analysis error: $e');
    }
  }

  Color get _iconColor => _isDarkBackground ? _lightIconColor : _darkIconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: LiquidGlass.withOwnLayer(
        settings: AppLiquidGlassSettings.button,
        shape: LiquidRoundedSuperellipse(borderRadius: 16.r),
        child: SizedBox(
          width: 44.w,
          height: 44.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: SvgPicture.asset(
                  'images/notif2.svg',
                  key: ValueKey(_isDarkBackground),
                  width: 24.w,
                  colorFilter: ColorFilter.mode(
                    _iconColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              if (widget.notificationCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 16.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFAD1A1A),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
                        widget.notificationCount > 9
                            ? '9+'
                            : '${widget.notificationCount}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
