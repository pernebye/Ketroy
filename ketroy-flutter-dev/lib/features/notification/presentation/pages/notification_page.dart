import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/notification/domain/entities/notification_entity.dart';
import 'package:ketroy_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:ketroy_app/features/notification/presentation/widgets/notifiication_card.dart';
import 'package:ketroy_app/services/notification_services.dart';
import 'package:ketroy_app/core/transitions/slide_over_page_route.dart';
import 'package:ketroy_app/features/notification/presentation/pages/notification_settings_page.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

/// Типы фильтров для уведомлений
enum NotificationFilter {
  unread, // Не прочитано
  debit, // Списание
  gifts, // Подарки
  discounts, // Скидки
  news, // Новости
  system, // Системные
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with WidgetsBindingObserver, RouteAware {
  static final RouteObserver<PageRoute> routeObserver =
      RouteObserver<PageRoute>();

  /// Текущий выбранный фильтр
  NotificationFilter _selectedFilter = NotificationFilter.unread;

  // Основной оливковый цвет из Figma
  static const Color _primaryGreen = Color(0xFF3C4B1B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    debugPrint('Returned to NotificationPage, refreshing...');
    _loadNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed, refreshing notifications');
      _loadNotifications();
    }
  }

  void _loadNotifications() {
    debugPrint('📋 _loadNotifications called');
    context.read<NotificationBloc>().add(GetNotificationListFetch());
  }

  /// Фильтрация уведомлений по выбранному фильтру
  List<NotificationEntity> _filterNotifications(
      List<NotificationEntity> notifications) {
    switch (_selectedFilter) {
      case NotificationFilter.unread:
        return notifications.where((n) => !n.isRead).toList();
      case NotificationFilter.debit:
        // Бонусы, ДР, лояльность
        final bonusLabels = ['bonus', 'bonuses', 'debit', 'birthday', 'loyalty', 'loyalty_level_up'];
        return notifications
            .where((n) => bonusLabels.contains(n.label?.toLowerCase()))
            .toList();
      case NotificationFilter.gifts:
        // Подарки, сертификаты
        final giftLabels = ['gift', 'gifts', 'new_gift', 'gift_received', 'gift_issuance', 
                           'pending_gift', 'lottery', 'certificate', 'certificates'];
        return notifications
            .where((n) => giftLabels.contains(n.label?.toLowerCase()))
            .toList();
      case NotificationFilter.discounts:
        // Скидки, промокоды, реферальная программа
        final discountLabels = ['discount', 'discounts', 'promo', 'promo_code', 'promocode', 
                               'referral', 'referral_applied'];
        return notifications
            .where((n) => discountLabels.contains(n.label?.toLowerCase()))
            .toList();
      case NotificationFilter.news:
        // Новости, информационные
        final newsLabels = ['news', 'info', 'information', 'reminder', 'custom_push', 'broadcast', 'promotion'];
        return notifications
            .where((n) => newsLabels.contains(n.label?.toLowerCase()))
            .toList();
      case NotificationFilter.system:
        // Системные, тестовые
        final systemLabels = ['system', 'test'];
        return notifications
            .where((n) => systemLabels.contains(n.label?.toLowerCase()))
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocConsumer<NotificationBloc, NotificationState>(
            listener: (BuildContext context, NotificationState state) {
              if (state.isSuccess) {
                _updateBadgeCount(state);
              }
            },
            builder: (BuildContext context, NotificationState state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === Custom AppBar ===
                  _buildCustomAppBar(),

                  // === Filter Tabs ===
                  _buildFilterTabs(),

                  // === Content ===
                  Expanded(
                    child: _buildContent(state),
                  ),

                  // === Кнопка "Прочитать все" ===
                  if (state.isSuccess && state.notificationList.isNotEmpty)
                    _buildMarkAllReadButton(state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Кастомный AppBar в стиле Figma
  Widget _buildCustomAppBar() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          // Кнопка назад
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 35.w,
              height: 35.w,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(19.r),
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18.sp,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Заголовок
          Expanded(
            child: Text(
              l10n.notificationsTitle,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 17.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          // Кнопка настроек
          GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              SlideOverPageRoute(page: const NotificationSettingsPage()),
            ),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: _primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.settings_rounded,
                size: 20.sp,
                color: _primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Горизонтальные фильтры — стили как на витрине новостей
  Widget _buildFilterTabs() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(bottom: 8.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(width: 16.w),
            _buildFilterChip(NotificationFilter.unread, l10n.filterUnread),
            SizedBox(width: 12.w),
            _buildFilterChip(NotificationFilter.debit, l10n.filterDebit),
            SizedBox(width: 12.w),
            _buildFilterChip(NotificationFilter.gifts, l10n.filterGifts),
            SizedBox(width: 12.w),
            _buildFilterChip(NotificationFilter.discounts, l10n.filterDiscounts),
            SizedBox(width: 12.w),
            _buildFilterChip(NotificationFilter.news, l10n.filterNews),
            SizedBox(width: 12.w),
            _buildFilterChip(NotificationFilter.system, l10n.filterSystem),
            SizedBox(width: 16.w),
          ],
        ),
      ),
    );
  }

  /// Чип фильтра — динамическая ширина по контенту
  Widget _buildFilterChip(NotificationFilter filter, String label) {
    final isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        height: 41.h,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: isSelected ? _primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(13.r),
          border: Border.all(
            color: isSelected
                ? _primaryGreen
                : Colors.black.withValues(alpha: 0.12),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 15.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black,
              letterSpacing: -0.24,
            ),
          ),
        ),
      ),
    );
  }

  void _updateBadgeCount(NotificationState state) async {
    try {
      await NotificationServices.instance
          .updateBadgeFromNotifications(state.notificationList);
    } catch (e) {
      debugPrint('Error updating badge count: $e');
    }
  }

  Widget _buildContent(NotificationState state) {
    if (state.isInitial || state.isLoading) {
      return const Center(child: Loader());
    }

    if (state.isFailure) {
      return _buildErrorWidget();
    }

    if (state.isSuccess) {
      final filteredList = _filterNotifications(state.notificationList);
      if (filteredList.isEmpty) {
        return _buildEmptyWidget();
      }
      return _buildNotificationsList(filteredList);
    }

    return const SizedBox();
  }

  Widget _buildNotificationsList(List<NotificationEntity> notifications) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<NotificationBloc>().add(GetNotificationListFetch());
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Padding(
            padding: EdgeInsets.only(
              top: index == 0 ? 8.h : 0,
              bottom: index == notifications.length - 1 ? 20.h : 0,
            ),
            child: NotificationCardWithAutoRefresh(
              notification: notification,
              onNavigationReturn: _loadNotifications,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyWidget() {
    final l10n = AppLocalizations.of(context)!;
    String emptyText;
    switch (_selectedFilter) {
      case NotificationFilter.unread:
        emptyText = l10n.noUnreadNotifications;
        break;
      case NotificationFilter.debit:
        emptyText = l10n.noDebitNotifications;
        break;
      case NotificationFilter.gifts:
        emptyText = l10n.noGiftNotifications;
        break;
      case NotificationFilter.discounts:
        emptyText = l10n.noDiscountNotifications;
        break;
      case NotificationFilter.news:
        emptyText = l10n.noNewsNotifications;
        break;
      case NotificationFilter.system:
        emptyText = l10n.noSystemNotifications;
        break;
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadNotifications();
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 350,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64.sp,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    emptyText,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: Colors.red[300],
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.loadError,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: () {
              context.read<NotificationBloc>().add(GetNotificationListFetch());
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: _primaryGreen,
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: Text(
                l10n.retry,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Кнопка "Прочитать все" — текстовая с подчёркиванием
  Widget _buildMarkAllReadButton(NotificationState state) {
    final l10n = AppLocalizations.of(context)!;
    // Показываем только если есть непрочитанные
    final hasUnread = state.notificationList.any((n) => !n.isRead);

    if (!hasUnread) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 24.h),
      child: Center(
        child: GestureDetector(
          onTap: () => _markAllAsRead(),
          child: Text(
            l10n.markAllAsRead,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              decoration: TextDecoration.underline,
              decorationColor: Colors.black,
              decorationThickness: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  /// Отметить все как прочитанные
  void _markAllAsRead() async {
    try {
      context.read<NotificationBloc>().add(MarkAllNotificationsAsReadFetch());
      await NotificationServices.instance.clearBadge();

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.allNotificationsMarkedRead),
            backgroundColor: _primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        context.read<NotificationBloc>().add(GetNotificationListFetch());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
