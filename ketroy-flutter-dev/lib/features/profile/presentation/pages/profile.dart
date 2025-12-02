import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ketroy_app/core/common/widgets/bonus_card.dart';
import 'package:ketroy_app/core/constants/shop_contacts.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart' show AppLiquidGlassSettings;
import 'package:ketroy_app/core/util/launch_url.dart';
import 'package:ketroy_app/services/analytics/social_analytics_service.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/auth/presentation/bloc/auth_bloc.dart' hide GetProfileUserFetch;
import 'package:ketroy_app/features/auth/presentation/pages/login_page.dart';
import 'package:ketroy_app/features/discount/presentation/bloc/discount_bloc.dart';
import 'package:ketroy_app/features/discount/presentation/pages/discount_page.dart';
import 'package:ketroy_app/features/my_gifts/presentation/pages/my_gifts.dart';
import 'package:ketroy_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:ketroy_app/features/profile/presentation/pages/profile_detail_page.dart';
import 'package:ketroy_app/features/settings/presentation/pages/settings_page.dart';
import 'package:ketroy_app/features/shop/presentation/pages/shop.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:ketroy_app/select_page.dart';
import 'package:ketroy_app/services/shared_preferences_service.dart';
import 'package:ketroy_app/core/common/widgets/auth_required_dialog.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';
import 'package:ketroy_app/core/transitions/slide_over_page_route.dart';
import 'package:ketroy_app/features/profile/presentation/widgets/promotion_card.dart';
import 'package:ketroy_app/features/profile/presentation/widgets/write_review_sheet.dart';
import 'package:ketroy_app/features/shop/presentation/bloc/shop_bloc.dart';
import 'package:ketroy_app/features/shop_detail/presentation/bloc/shop_detail_bloc.dart';
import 'package:ketroy_app/features/partners/presentation/pages/partners_page.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:ketroy_app/services/notification_services.dart';

class ProfilePage extends StatefulWidget {
  final bool? fromGift;
  final bool showBonusTab;
  
  const ProfilePage({
    super.key, 
    this.fromGift,
    this.showBonusTab = false,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late bool account;
  final sharedService = serviceLocator<SharedPreferencesService>();
  
  // Подписка на события обновления бонусов
  StreamSubscription<BonusUpdateEvent>? _bonusUpdateSubscription;
  
  // PageController для свайп-навигации между вкладками
  late PageController _pageController;

  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _darkBg = Color(0xFF1A1F12);
  static const Color _cardBg = Color(0xFFF5F7F0);

  late AnimationController _headerAnimController;
  late AnimationController _menuAnimController;
  late List<Animation<double>> _menuAnimations;

  @override
  void initState() {
    super.initState();
    
    // Если showBonusTab = true, показываем вкладку "Бонусы" (account = false)
    // Иначе показываем вкладку "Аккаунт" (account = true)
    account = !widget.showBonusTab;
    
    // Инициализируем PageController с начальной страницей
    _pageController = PageController(initialPage: account ? 0 : 1);
    
    _initializeProfile();
    _setupBonusUpdateListener();

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _menuAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _menuAnimations = List.generate(7, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _menuAnimController,
          curve: Interval(
            index * 0.08,
            0.5 + index * 0.08,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _menuAnimController.forward();
    });

    if (widget.fromGift ?? false) {
      Navigator.push(
          context, SlideOverPageRoute(page: const MyGifts()));
    }
  }
  
  /// Подписка на события обновления бонусов из push-уведомлений
  void _setupBonusUpdateListener() {
    _bonusUpdateSubscription = NotificationServices.instance.onBonusUpdate.listen((event) {
      debugPrint('💰 Received bonus update event: ${event.operation} ${event.amount}');
      if (mounted) {
        // Запрашиваем актуальные данные пользователя с сервера
        // Бонусы обновятся автоматически с анимацией через AnimatedBonusCounter
        context.read<ProfileBloc>().add(RefreshBonusFromServer(
          expectedAmount: event.amount,
        ));
      }
    });
  }

  @override
  void dispose() {
    _bonusUpdateSubscription?.cancel();
    _headerAnimController.dispose();
    _menuAnimController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _initializeProfile() {
    context.read<ProfileBloc>()
      ..add(LoadUserInfo())
      ..add(GetDiscountFetch())
      ..add(LoadCityShop()) // Загружаем магазин для соцсетей
      ..add(GetPromotionsFetch()) // Загружаем акции для вкладки бонусов
      ..add(const RefreshBonusFromServer()); // Обновляем бонусы с сервера
    // Проверяем доступность реферальной программы
    context.read<DiscountBloc>().add(CheckReferralAvailability());
  }

  Future<void> _navigateAndFetchReviews(ProfileState state) async {
    await Navigator.of(context, rootNavigator: true).push(
        SlideOverPageRoute(page: const ProfileDetailPage()));

    if (!mounted) return;
    context.read<ProfileBloc>().add(GetProfileUserFetch());
  }

  Future<void> _loadUserData(ProfileState state) async {
    context.read<ProfileBloc>().add(ResetProfileState());
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _initializeProfile();
    if (state.token != null && _hasUserData(state)) {
      context.read<ProfileBloc>().add(GetProfileUserFetch());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _cardBg,
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state.isFailure) {
              showSnackBar(context, state.message ?? '');
              _handleAuthenticationFailure();
            }
            if (state.isCleaned == true) {
              _handleAccountCleanup();
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: Loader());
            }
            return _buildContent(state);
          },
        ),
      ),
    );
  }

  // Ключ для измерения высоты хедера
  final GlobalKey _headerKey = GlobalKey();
  double _gradientHeight = 0;
  bool _headerMeasured = false;

  void _measureHeaderHeight() {
    final context = _headerKey.currentContext;
    if (context != null) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final newHeight = renderBox.size.height + 32.h; // +32 для комфортного отступа
        if (!_headerMeasured || (_gradientHeight - newHeight).abs() > 5) {
          setState(() {
            _gradientHeight = newHeight;
            _headerMeasured = true;
          });
        }
      }
    }
  }

  /// Синхронизирует позицию PageController с текущим состоянием вкладки
  void _syncPageControllerWithTabState() {
    if (!_pageController.hasClients) return;
    
    final targetPage = account ? 0 : 1;
    final currentPage = _pageController.page?.round() ?? 0;
    
    // Если PageController не на правильной странице - перепрыгиваем без анимации
    if (currentPage != targetPage) {
      _pageController.jumpToPage(targetPage);
    }
  }

  // Минимальная высота градиента
  static double get _minGradientHeight => 180.h;

  double get _effectiveGradientHeight {
    if (_headerMeasured) {
      return _gradientHeight.clamp(_minGradientHeight, double.infinity);
    }
    // Fallback: используем процент от экрана для первого рендера
    return MediaQuery.of(context).size.height * 0.42;
  }

  Widget _buildContent(ProfileState state) {
    final hasUserData = state.token != null && _hasUserData(state);

    // Измеряем хедер и синхронизируем PageController после каждого билда
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureHeaderHeight();
      _syncPageControllerWithTabState();
    });

    return Stack(
      children: [
        // Адаптивный фоновый градиент
        _buildBackground(),

        // Основной контент
        RefreshIndicator(
          color: _accentGreen,
          onRefresh: () => _loadUserData(state),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header с профилем (с ключом для измерения)
              SliverToBoxAdapter(
                child: KeyedSubtree(
                  key: _headerKey,
                  child: _buildProfileHeader(state, hasUserData),
                ),
              ),

              // Контент
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32.r),
                      topRight: Radius.circular(32.r),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
                    child: Column(
                      children: [
                        if (hasUserData) ...[
                          _buildTabSwitcher(),
                          SizedBox(height: 24.h),
                          // PageView для свайп-навигации между вкладками
                          SizedBox(
                            // Высота для контента вкладок
                            height: _calculateTabContentHeight(state),
                            child: PageView(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  account = index == 0;
                                });
                              },
                              children: [
                                // Страница 0: Аккаунт
                                SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: Column(
                                    children: [
                                      _buildMenuCard(state),
                                      SizedBox(height: 24.h),
                                      _buildSocialLinks(state),
                                    ],
                                  ),
                                ),
                                // Страница 1: Бонусы
                                SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: Column(
                                    children: [
                                      _buildTabContent(state),
                                      SizedBox(height: 24.h),
                                      _buildPromotionsSection(state),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          _buildMenuCard(state),
                          SizedBox(height: 24.h),
                          _buildSocialLinks(state),
                        ],
                        SizedBox(height: 32.h),
                        _buildFooter(),
                        SizedBox(height: NavBar.getBottomPadding(context)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackground() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: _effectiveGradientHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _darkBg,
            _primaryGreen,
            _lightGreen.withValues(alpha: 0.8),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ProfileState state, bool hasUserData) {
    return AnimatedBuilder(
      animation: _headerAnimController,
      builder: (context, child) {
        final value = _headerAnimController.value;
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          child: Column(
            children: [
              // Toolbar
              _buildToolbar(state),
              SizedBox(height: 24.h),

              // Avatar и информация
              if (hasUserData) ...[
                _buildAvatarSection(state),
                SizedBox(height: 16.h),
                _buildUserInfo(state),
              ] else ...[
                _buildGuestHeader(),
              ],
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(ProfileState state) {
    final canPop = Navigator.canPop(context);
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        if (canPop)
          _buildToolbarButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          )
        else
          SizedBox(width: 44.w),
        const Spacer(),
        Text(
          l10n.profile,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        _buildToolbarButton(
          icon: Icons.settings_outlined,
          onTap: () => _navigateToSettings(),
        ),
      ],
    );
  }
  
  void _navigateToSettings() {
    Navigator.of(context, rootNavigator: true).push(
      SlideOverPageRoute(page: const SettingsPage()),
    );
  }

  /// Открытие страницы "Мои подарки" с проверкой авторизации
  void _openMyGifts(ProfileState state) {
    final l10n = AppLocalizations.of(context)!;
    
    // Проверяем авторизацию
    if (state.token == null) {
      AuthRequiredDialog.show(
        context,
        title: l10n.authRequired,
        message: l10n.authRequiredMessage,
      );
      return;
    }
    
    Navigator.of(context, rootNavigator: true).push(
      SlideOverPageRoute(page: const MyGifts()),
    );
  }

  void _showWriteReviewSheet(ProfileState state) {
    final userId = state.profileData?.id.toString() ?? '';
    if (userId.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: serviceLocator<ShopBloc>()),
          BlocProvider.value(value: serviceLocator<ShopDetailBloc>()),
        ],
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 50.h,
          ),
          child: WriteReviewSheet(userId: userId),
        ),
      ),
    );
  }

  Widget _buildToolbarButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlass.withOwnLayer(
        settings: AppLiquidGlassSettings.button,
        shape: LiquidRoundedSuperellipse(borderRadius: 22.r),
        child: SizedBox(
          width: 44.w,
          height: 44.w,
          child: Icon(
            icon,
            size: 20.sp,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(ProfileState state) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        _buildAvatar(state),
        _buildEditAvatarButton(),
      ],
    );
  }

  Widget _buildAvatar(ProfileState state) {
    final hasAvatar =
        state.avatarImage != null && state.avatarImage!.isNotEmpty;
    final size = 110.w;
    final isNetworkImage = hasAvatar && 
        (state.avatarImage!.startsWith('http://') || 
         state.avatarImage!.startsWith('https://'));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: hasAvatar
            ? isNetworkImage
                ? Image.network(
                    state.avatarImage!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _accentGreen,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildInitialAvatar(state);
                    },
                  )
                : Image.file(
                    File(state.avatarImage!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildInitialAvatar(state);
                    },
                  )
            : _buildInitialAvatar(state),
      ),
    );
  }

  Widget _buildInitialAvatar(ProfileState state) {
    String initial = '';
    if (state.name != null && state.name!.isNotEmpty) {
      initial = state.name!.substring(0, 1).toUpperCase();
    } else {
      initial = 'U';
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accentGreen,
            _lightGreen,
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 42.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEditAvatarButton() {
    return GestureDetector(
      onTap: _onAvatarEditTap,
      child: Container(
        width: 38.w,
        height: 38.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [_accentGreen, _lightGreen],
          ),
          boxShadow: [
            BoxShadow(
              color: _accentGreen.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.camera_alt_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  void _onAvatarEditTap() {
    context.read<ProfileBloc>().add(UploadProfileImage());
  }

  Widget _buildUserInfo(ProfileState state) {
    final l10n = AppLocalizations.of(context)!;
    final fullName = '${state.name ?? ''} ${state.surname ?? ''}'.trim();
    return Column(
      children: [
        Text(
          fullName.isEmpty ? l10n.user : fullName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_outlined,
              size: 16.w,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            SizedBox(width: 6.w),
            Text(
              _buildProfileSubtitle(state),
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuestHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
          width: 100.w,
          height: 100.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.person_outline_rounded,
            size: 48.w,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          l10n.welcome,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          l10n.loginForFullAccess,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  String _buildProfileSubtitle(ProfileState state) {
    final phone = state.phoneNumber;
    if (phone != null && phone.isNotEmpty && phone.length >= 10) {
      // Форматируем телефон: 7474747485 -> +7 (747) 474-74-85
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 10) {
        final code = digits.substring(0, 3);
        final part1 = digits.substring(3, 6);
        final part2 = digits.substring(6, 8);
        final part3 = digits.substring(8, 10);
        return '+7 ($code) $part1-$part2-$part3';
      }
      return '+7 $phone';
    }
    return '+7 (---) --- -- --';
  }

  Widget _buildTabSwitcher() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: l10n.account,
              icon: Icons.person_outline_rounded,
              isActive: account,
              onTap: () {
                if (!account) {
                  setState(() => account = true);
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: l10n.bonuses,
              icon: Icons.card_giftcard_rounded,
              isActive: !account,
              onTap: () {
                if (account) {
                  setState(() => account = false);
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [_lightGreen, _primaryGreen],
                )
              : null,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18.w,
              color: isActive ? Colors.white : _primaryGreen.withValues(alpha: 0.6),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 15.sp,
                color: isActive ? Colors.white : _primaryGreen.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasUserData(ProfileState state) {
    return state.name != null || state.phoneNumber != null;
  }

  Widget _buildMenuCard(ProfileState state) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildMenuItems(state),
    );
  }

  Widget _buildMenuItems(ProfileState state) {
    final l10n = AppLocalizations.of(context)!;
    final hasUserData = state.token != null && _hasUserData(state);
    final isReferralAvailable = context.watch<DiscountBloc>().state.isReferralAvailable;
    
    final menuItems = [
      _MenuItem(
        icon: Icons.person_outline_rounded,
        title: l10n.profileSettings,
        onTap: () => _navigateAndFetchReviews(state),
      ),
      _MenuItem(
        icon: Icons.store_outlined,
        title: l10n.shops,
        onTap: () => Navigator.of(context, rootNavigator: true).push(
          SlideOverPageRoute(page: const ShopPage(pop: true)),
        ),
      ),
      if (hasUserData)
        _MenuItem(
          icon: Icons.rate_review_outlined,
          title: l10n.writeReview,
          onTap: () => _showWriteReviewSheet(state),
        ),
      _MenuItem(
        icon: Icons.card_giftcard_rounded,
        title: l10n.myGifts,
        onTap: () => _openMyGifts(state),
      ),
      _MenuItem(
        icon: Icons.handshake_rounded,
        title: l10n.forPartners,
        onTap: () => Navigator.of(context, rootNavigator: true).push(
          SlideOverPageRoute(page: const PartnersPage()),
        ),
      ),
      // Показываем кнопку "Подари скидку другу" только если акция активна
      if (isReferralAvailable)
        _MenuItem(
          icon: Icons.share_rounded,
          title: l10n.shareDiscount,
          onTap: () {
            context.read<DiscountBloc>().add(GetPromoCodeFetch());
            Navigator.of(context, rootNavigator: true).push(
              SlideOverPageRoute(page: const DiscountPage()),
            );
          },
        ),
    ];

    return Column(
      children: List.generate(menuItems.length, (index) {
        return AnimatedBuilder(
          animation: _menuAnimations[index.clamp(0, _menuAnimations.length - 1)],
          builder: (context, child) {
            final value = _menuAnimations[index.clamp(0, _menuAnimations.length - 1)].value;
            return Transform.translate(
              offset: Offset(20 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _buildMenuItem(menuItems[index], index == menuItems.length - 1),
        );
      }),
    );
  }

  Widget _buildMenuItem(_MenuItem item, bool isLast) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: _primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                item.icon,
                color: _primaryGreen,
                size: 22.w,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.black26,
              size: 22.w,
            ),
          ],
        ),
      ),
    );
  }

  /// Вычисляет высоту контента для PageView
  /// Возвращает достаточную высоту для обеих вкладок
  double _calculateTabContentHeight(ProfileState state) {
    // Примерное количество пунктов меню в аккаунте (6-7 пунктов)
    const menuItemCount = 7;
    // Высота одного пункта меню + padding
    final menuItemHeight = 70.h;
    // Высота меню карточки (items + padding)
    final menuCardHeight = (menuItemCount * menuItemHeight) + 40.h;
    // Высота соцсетей (заголовок + иконки + padding)
    final socialLinksHeight = 140.h;
    // Общая высота для вкладки "Аккаунт"
    final accountHeight = menuCardHeight + socialLinksHeight + 24.h;
    
    // Высота бонусной карточки
    final bonusCardHeight = 240.h;
    // Высота секции акций (заголовок + примерно 2-3 акции)
    final promotionsCount = state.promotions?.length ?? 0;
    final promotionsHeight = promotionsCount > 0 
        ? (80.h + (promotionsCount.clamp(0, 5) * 140.h)) 
        : 100.h;
    // Общая высота для вкладки "Бонусы"
    final bonusHeight = bonusCardHeight + promotionsHeight + 24.h;
    
    // Возвращаем максимальную высоту + запас
    return (accountHeight > bonusHeight ? accountHeight : bonusHeight) + 80.h;
  }

  Widget _buildTabContent(ProfileState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BonusCardWidget(
          qrButton: true,
          discount: state.discount,
          bonus: state.bonus ?? '0',
          onRefresh: () => _refreshAfterQR(state),
        ),
      ],
    );
  }

  Widget _buildSocialLinks(ProfileState state) {
    final l10n = AppLocalizations.of(context)!;
    final userCity = state.city;
    final cityShop = state.cityShop;

    // Получаем ссылки из магазина города пользователя или используем fallback
    Uri? whatsAppUrl;
    Uri? instagramUrl;
    Uri? twoGisUrl;

    if (cityShop != null) {
      // Ссылки из магазина по городу пользователя
      if (cityShop.whatsApp.isNotEmpty) {
        whatsAppUrl = Uri.tryParse('https://wa.me/${cityShop.whatsApp}');
      }
      if (cityShop.instagram.isNotEmpty) {
        instagramUrl = Uri.tryParse(cityShop.instagram);
      }
      if (cityShop.twoGisAddress.isNotEmpty) {
        twoGisUrl = Uri.tryParse(cityShop.twoGisAddress);
      }
    }

    // Fallback на статические ссылки если магазин не загружен
    whatsAppUrl ??= WhatsAppContacts.almatyWhatsapp;
    instagramUrl ??= InstaContacts.almatyInsta;
    twoGisUrl ??= Uri.parse('https://go.2gis.com/ketroy');
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.weInSocials,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: _primaryGreen,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildSocialButton(
                asset: 'images/whats.svg',
                label: 'WhatsApp',
                onTap: () {
                  socialAnalytics.trackWhatsAppFromNavBar(
                    city: userCity,
                    url: whatsAppUrl.toString(),
                  );
                  launchURL(whatsAppUrl!);
                },
              ),
              SizedBox(width: 12.w),
              _buildSocialButton(
                asset: 'images/insta.svg',
                label: 'Instagram',
                onTap: () {
                  socialAnalytics.trackInstagramFromNavBar(
                    city: userCity,
                    url: instagramUrl.toString(),
                  );
                  launchURL(instagramUrl!);
                },
              ),
              SizedBox(width: 12.w),
              _buildSocialButton(
                asset: 'images/2gis.svg',
                label: '2ГИС',
                onTap: () {
                  socialAnalytics.track2GisFromShop(
                    shopId: cityShop?.id ?? 0,
                    shopName: cityShop?.name ?? 'KETROY',
                    url: twoGisUrl.toString(),
                  );
                  launchURL(twoGisUrl!);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String asset,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                asset,
                width: 28.w,
                height: 28.w,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Секция с горизонтальным скроллингом акций
  Widget _buildPromotionsSection(ProfileState state) {
    final l10n = AppLocalizations.of(context)!;
    final promotions = state.promotions;
    final isLoading = state.promotionsStatus == PromotionsStatus.loading;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer_rounded,
                size: 18.sp,
                color: _primaryGreen,
              ),
              SizedBox(width: 8.w),
              Text(
                l10n.currentPromotions,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: _primaryGreen,
                ),
              ),
              const Spacer(),
              if (promotions.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${promotions.length}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _primaryGreen,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          if (isLoading)
            SizedBox(
              height: 160.h,
              child: const Center(
                child: CircularProgressIndicator(
                  color: _accentGreen,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (promotions.isEmpty)
            _buildEmptyPromotions()
          else
            SizedBox(
              height: 170.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: promotions.length,
                itemBuilder: (context, index) {
                  return PromotionCard(promotion: promotions[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyPromotions() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 120.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 40.sp,
            color: Colors.black26,
          ),
          SizedBox(height: 12.h),
          Text(
            l10n.noActivePromotions,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black45,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            l10n.checkBackLater,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return GestureDetector(
      onTap: () => launchURL(Uri.parse('https://ozimiz-it.com')),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.code_rounded,
                  size: 14.sp,
                  color: Colors.black38,
                ),
                SizedBox(width: 6.w),
                Text(
                  'OZIMIZ OUTSOURCE',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black38,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'KETROY v2.0',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.black26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshAfterQR(ProfileState state) {
    debugPrint('🔄 Refreshing discount after QR scan...');
    // Только обновляем скидку, не сбрасываем всё состояние
    context.read<ProfileBloc>().add(GetDiscountFetch());
  }

  void _handleAccountCleanup() {
    sharedService.passed = false;
    sharedService.profilePassed = false;
    sharedService.deviceTokenPassed = false;
    
    // Сбрасываем состояние авторизации для чистого входа
    context.read<AuthBloc>().add(const AuthResetState());

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => SelectPage()),
        (route) => route.isFirst,
      );
    }
  }

  void _handleAuthenticationFailure() {
    sharedService.passed = false;
    sharedService.profilePassed = false;
    sharedService.deviceTokenPassed = false;
    
    // Сбрасываем состояние авторизации для чистого входа
    context.read<AuthBloc>().add(const AuthResetState());
    context.read<ProfileBloc>().add(LogOutFetch());

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => route.isFirst,
      );
    }
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
