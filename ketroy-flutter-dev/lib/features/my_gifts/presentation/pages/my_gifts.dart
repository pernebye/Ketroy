import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';
import 'package:ketroy_app/features/active_gifts/presentation/view_model/all_gifts_view_model.dart';
import 'package:ketroy_app/features/active_gifts/widgets/my_gifts_widget.dart';
import 'package:ketroy_app/features/my_gifts/presentation/bloc/gifts_bloc.dart';
import 'package:ketroy_app/features/my_gifts/presentation/pages/gift_selection_page.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:ketroy_app/services/notification_services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';

class MyGifts extends StatelessWidget {
  final bool showBackButton;
  
  const MyGifts({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AllGiftsViewModel>(
      create: (context) => AllGiftsViewModel(),
      child: MyGiftsContent(showBackButton: showBackButton),
    );
  }
}

class MyGiftsContent extends StatefulWidget {
  final bool showBackButton;
  
  const MyGiftsContent({super.key, this.showBackButton = true});

  @override
  State<MyGiftsContent> createState() => _MyGiftsContentState();
}

class _MyGiftsContentState extends State<MyGiftsContent>
    with SingleTickerProviderStateMixin {
  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _darkBg = Color(0xFF1A1F12);
  static const Color _cardBg = Color(0xFFF5F7F0);

  late AnimationController _animController;
  StreamSubscription<NewGiftEvent>? _giftEventSubscription;
  
  // Для анимации нового подарка
  bool _showNewGiftBanner = false;
  String? _newGiftName;

  @override
  void initState() {
    super.initState();
    context.read<GiftsBloc>().add(GetGiftsListFetch());
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    
    // Подписываемся на события новых подарков
    _giftEventSubscription = NotificationServices.instance.onNewGift.listen(_onNewGiftReceived);
  }

  @override
  void dispose() {
    _giftEventSubscription?.cancel();
    _animController.dispose();
    super.dispose();
  }
  
  /// Обработка события нового подарка
  void _onNewGiftReceived(NewGiftEvent event) {
    debugPrint('🎁 MyGifts: New gift event received - ${event.giftName}');
    
    if (!mounted) return;
    
    // Показываем баннер о новом подарке
    setState(() {
      _showNewGiftBanner = true;
      _newGiftName = event.giftName;
    });
    
    // Виброотклик
    HapticFeedback.mediumImpact();
    
    // Перезапускаем анимацию для плавного появления новых элементов
    _animController.reset();
    _animController.forward();
    
    // Обновляем список подарков
    context.read<GiftsBloc>().add(GetGiftsListFetch());
    
    // Скрываем баннер через 4 секунды
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showNewGiftBanner = false;
          _newGiftName = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: widget.showBackButton ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _cardBg,
        body: BlocConsumer<GiftsBloc, GiftsState>(
          listener: (context, state) {
            if (state.isActivate) {
              _showActivationSuccessDialog(context, state, l10n);
            }
          },
          builder: (context, state) {
            // Если без кнопки назад (из навбара) — layout с простым header
            if (!widget.showBackButton) {
              return Stack(
                children: [
                  Column(
                    children: [
                      // Header простирается до status bar (белый фон за ним)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: _buildSimpleHeader(l10n),
                        ),
                      ),
                      Expanded(
                        child: _buildContent(state, l10n),
                      ),
                    ],
                  ),
                  // Баннер о новом подарке
                  if (_showNewGiftBanner)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _buildNewGiftBanner(),
                    ),
                ],
              );
            }
            
            // С header (из профиля)
            return Stack(
              children: [
                // Градиентный header
                Container(
                  height: 180.h,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_darkBg, _primaryGreen],
                    ),
                  ),
                ),

                // Контент
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(l10n),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(top: 16.h),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32.r),
                              topRight: Radius.circular(32.r),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32.r),
                              topRight: Radius.circular(32.r),
                            ),
                            child: _buildContent(state, l10n),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Баннер о новом подарке
                if (_showNewGiftBanner)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildNewGiftBanner(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Простой header для режима из навбара (часть страницы, не overlay)
  Widget _buildSimpleHeader(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_lightGreen, _primaryGreen],
              ),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Image.asset(
              'images/giftR.png',
              fit: BoxFit.contain,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.myGifts,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  l10n.yourSavedGifts,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          if (widget.showBackButton)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: LiquidGlass.withOwnLayer(
                shape: LiquidRoundedSuperellipse(borderRadius: 22.r),
                child: SizedBox(
                  width: 44.w,
                  height: 44.w,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
            )
          else
            SizedBox(width: 16.w),
          Expanded(
            child: Column(
              children: [
                Text(
                  l10n.myGifts,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'images/giftR.png',
                      width: 16.w,
                      height: 16.w,
                      fit: BoxFit.contain,
                      color: _accentGreen,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      l10n.yourSavedGifts,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.showBackButton)
            SizedBox(width: 44.w)
          else
            SizedBox(width: 16.w),
        ],
      ),
    );
  }

  Widget _buildContent(GiftsState state, AppLocalizations l10n) {
    // Показываем спиннер при загрузке (только если ещё нет данных)
    if (state.isLoading || state.isInitial) {
      // Если уже есть какие-то данные - не показываем спиннер
      if (state.savedGiftsList.isEmpty && state.gifts.isEmpty && !state.hasPending) {
        return _buildLoadingState();
      }
    }
    
    // Показываем ошибку при неудачной загрузке
    if (state.isFailure && state.savedGiftsList.isEmpty && state.gifts.isEmpty) {
      return _buildErrorState(l10n, state.message);
    }
    
    // Объединяем все подарки: и сохранённые (isViewed=1), и новые (isViewed=0)
    final allGifts = [...state.savedGiftsList, ...state.gifts];
    
    // Сортируем по дате обновления (новые сверху)
    allGifts.sort((a, b) {
      final dateA = a.updatedAt ?? a.createdAt;
      final dateB = b.updatedAt ?? b.createdAt;
      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA); // Новые в начале
    });
    
    final hasPending = state.hasPending && state.pendingGroups.isNotEmpty;
    
    // Вычисляем нижний padding для NavBar (только если из навбара)
    final bottomPadding = widget.showBackButton ? 20.h : NavBar.getBottomPadding(context);
    
    if (allGifts.isEmpty && !hasPending) {
      return _buildEmptyState(l10n);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, bottomPadding),
      children: [
        // Секция ожидающих подарков
        if (hasPending) ...[
          _buildPendingGiftsSection(state, l10n),
          SizedBox(height: 24.h),
        ],
        
        // Список обычных подарков
        ...allGifts.asMap().entries.map((entry) {
          final index = entry.key;
          final gift = entry.value;
          return AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final delay = (index * 0.1).clamp(0.0, 0.5);
              final value = Curves.easeOut.transform(
                ((_animController.value - delay) / (1 - delay)).clamp(0.0, 1.0),
              );
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: MyGiftsWidget(
                  gift: gift,
                  onIssuanceComplete: () {
                    // Обновляем список после успешной выдачи
                    context.read<GiftsBloc>().add(GetGiftsListFetch());
                  },
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPendingGiftsSection(GiftsState state, AppLocalizations l10n) {
    final pendingCount = state.pendingGroups.length;
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryGreen, _lightGreen],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Image.asset(
                  'images/giftR.png',
                  fit: BoxFit.contain,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pendingGiftsTitle(pendingCount),
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      l10n.selectGiftNow,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          // Кнопки для каждой группы подарков
          ...state.pendingGroups.asMap().entries.map((entry) {
            final index = entry.key;
            final group = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index < state.pendingGroups.length - 1 ? 10.h : 0),
              child: GestureDetector(
                onTap: () async {
                  // Открываем экран выбора подарка напрямую
                  final selected = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GiftSelectionPage(
                        giftGroupId: group.giftGroupId,
                        gifts: group.gifts,
                      ),
                    ),
                  );
                  
                  if (selected == true && mounted) {
                    // Обновляем список подарков после успешного выбора
                    context.read<GiftsBloc>().add(GetGiftsListFetch());
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: _accentGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Center(
                          child: Image.asset(
                            'images/giftR.png',
                            width: 24.w,
                            height: 24.w,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.giftNumber(index + 1),
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: _primaryGreen,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              l10n.variantsCount(group.gifts.length),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_lightGreen, _primaryGreen],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          l10n.selectButton,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Контейнер с иконкой подарка
          Container(
            width: 80.w,
            height: 80.w,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_lightGreen.withValues(alpha: 0.2), _primaryGreen.withValues(alpha: 0.15)],
              ),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'images/giftR.png',
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: 24.w,
            height: 24.w,
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(_primaryGreen),
            ),
          ),
          SizedBox(height: 16.h),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Text(
                l10n.loadingGifts,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.black54,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, String? errorMessage) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40.w,
                color: Colors.red.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              l10n.failedToLoad,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              errorMessage ?? l10n.checkInternet,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black45,
              ),
            ),
            SizedBox(height: 24.h),
            // Кнопка повторить
            GestureDetector(
              onTap: () {
                context.read<GiftsBloc>().add(GetGiftsListFetch());
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: _primaryGreen,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20.w,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      l10n.retry,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Баннер о новом подарке с анимацией
  Widget _buildNewGiftBanner() {
    return SafeArea(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: -100.0, end: 0.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value),
            child: child,
          );
        },
        child: Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_accentGreen, _primaryGreen],
            ),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Анимированная иконка подарка
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Transform.rotate(
                      angle: (1 - value) * 0.5,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 52.w,
                  height: 52.w,
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Image.asset(
                    'images/giftR.png',
                    fit: BoxFit.contain,
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Row(
                          children: [
                            Text(
                              '🎉 ',
                              style: TextStyle(fontSize: 16.sp),
                            ),
                            Text(
                              l10n.newGiftBanner,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (_newGiftName != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        _newGiftName!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 2.h),
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Text(
                          l10n.listUpdated,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Кнопка закрытия
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showNewGiftBanner = false;
                    _newGiftName = null;
                  });
                },
                child: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 18.w,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: _primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'images/giftR.png',
                fit: BoxFit.contain,
                color: _primaryGreen.withValues(alpha: 0.5),
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              l10n.noGiftsYet,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.saveGiftsHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.black45,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivationSuccessDialog(BuildContext context, GiftsState state, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    color: _accentGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: _accentGreen,
                    size: 36.w,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  l10n.giftActivated,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  l10n.dontCloseWindow,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24.h),
                GestureDetector(
                  onTap: () async {
                    final allVm = context.read<AllGiftsViewModel>();
                    if (state.savedGiftsList.isNotEmpty) {
                      final firstGift = state.savedGiftsList.first;
                      allVm.addItem(
                        firstGift.image ?? 'default_image',
                        firstGift.id,
                        l10n.activatedGiftNumber(firstGift.id.toString()),
                      );
                    }
                    context.read<GiftsBloc>().add(ResetStateFetch());
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    await Future.delayed(const Duration(milliseconds: 100));
                    NavScreen.globalKey.currentState?.switchToTab(4, popToFirst: true);
                    NavScreen.globalKey.currentState?.updateNavState();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_lightGreen, _primaryGreen]),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Center(
                      child: Text(
                        l10n.done,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
