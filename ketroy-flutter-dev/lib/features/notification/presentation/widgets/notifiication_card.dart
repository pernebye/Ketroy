import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/transitions/slide_over_page_route.dart';
import 'package:ketroy_app/features/certificates/presentation/pages/certificate_page.dart';
import 'package:ketroy_app/features/discount/presentation/pages/discount_page.dart';
import 'package:ketroy_app/features/my_gifts/presentation/pages/my_gifts.dart';
import 'package:ketroy_app/features/news/presentation/pages/news_page_detail.dart';
import 'package:ketroy_app/features/notification/domain/entities/notification_entity.dart';
import 'package:ketroy_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:ketroy_app/features/profile/presentation/pages/profile.dart';
import 'package:ketroy_app/services/notification_services.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

enum NotificationLabelType {
  news,
  bonus,
  gift,
  certificate,
  discount,
  info,
  promo,
  reminder,
  system,
  test,
  birthday,
  customPush,
  loyalty,
  referral,
}

class NotificationCardWithAutoRefresh extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onNavigationReturn;

  const NotificationCardWithAutoRefresh({
    super.key,
    required this.notification,
    required this.onNavigationReturn,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleNotificationTap(context),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Иконка типа уведомления (60x60) ===
            _buildNotificationIcon(),

            SizedBox(width: 13.w),

            // === Контент уведомления ===
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4.h),

                  // Текст уведомления
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: 8.w),

            // === Время (относительное) ===
            Text(
              _formatRelativeTime(context, notification.createdAt),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Иконка уведомления на основе типа (50x50, borderRadius 10)
  /// Использует 3D изображения из Figma
  Widget _buildNotificationIcon() {
    final labelType = _getNotificationLabelType(notification.label);

    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: _getIconImage(labelType),
    );
  }

  /// 3D изображение по типу уведомления
  Widget _getIconImage(NotificationLabelType type) {
    String imagePath;

    switch (type) {
      case NotificationLabelType.bonus:
      case NotificationLabelType.birthday:
      case NotificationLabelType.loyalty:
        // Золотая монета тенге для списания/начисления бонусов и бонусов ДР
        imagePath = 'images/notif_coin.png';
        break;
      case NotificationLabelType.gift:
        // Подарочная коробка для подарков
        imagePath = 'images/notif_gift.png';
        break;
      case NotificationLabelType.certificate:
        // Сертификат — используем подарок
        imagePath = 'images/notif_gift.png';
        break;
      case NotificationLabelType.discount:
      case NotificationLabelType.promo:
      case NotificationLabelType.referral:
        // Чёрная бирка скидки
        imagePath = 'images/notif_discount.png';
        break;
      case NotificationLabelType.news:
      case NotificationLabelType.info:
      case NotificationLabelType.reminder:
      case NotificationLabelType.customPush:
        // Новости и информационные уведомления
        imagePath = 'images/news.png';
        break;
      case NotificationLabelType.system:
      case NotificationLabelType.test:
        // Системные уведомления
        imagePath = 'images/system.png';
        break;
    }

    return Image.asset(
      imagePath,
      width: 50.w,
      height: 50.w,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback на иконку если изображение не найдено
        return _getFallbackIcon(type);
      },
    );
  }

  /// Fallback иконка если изображение не найдено
  Widget _getFallbackIcon(NotificationLabelType type) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (type) {
      case NotificationLabelType.bonus:
      case NotificationLabelType.birthday:
      case NotificationLabelType.loyalty:
        icon = Icons.monetization_on_rounded;
        color = const Color(0xFFFFB300);
        bgColor = const Color(0xFFFFF8E1);
        break;
      case NotificationLabelType.gift:
      case NotificationLabelType.certificate:
        icon = Icons.card_giftcard_rounded;
        color = const Color(0xFF4CAF50);
        bgColor = const Color(0xFFE8F5E9);
        break;
      case NotificationLabelType.discount:
      case NotificationLabelType.promo:
      case NotificationLabelType.referral:
        icon = Icons.local_offer_rounded;
        color = const Color(0xFF212121);
        bgColor = const Color(0xFFF5F5F5);
        break;
      case NotificationLabelType.news:
      case NotificationLabelType.info:
      case NotificationLabelType.reminder:
      case NotificationLabelType.customPush:
        icon = Icons.newspaper_rounded;
        color = const Color(0xFF1976D2);
        bgColor = const Color(0xFFE3F2FD);
        break;
      case NotificationLabelType.system:
      case NotificationLabelType.test:
        icon = Icons.settings_rounded;
        color = const Color(0xFF607D8B);
        bgColor = const Color(0xFFECEFF1);
        break;
    }

    return Container(
      color: bgColor,
      child: Center(
        child: Icon(icon, size: 26.sp, color: color),
      ),
    );
  }

  /// Форматирование относительного времени
  /// Показывает: "Сейчас", "5 минут назад", "2 часа назад", "Вчера",
  /// "Понедельник" (для текущей недели), "2 недели назад", "1 месяц назад", "1 год назад"
  String _formatRelativeTime(BuildContext context, DateTime time) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(time);

    // Сейчас (меньше минуты)
    if (difference.inMinutes < 1) {
      return l10n.timeNow;
    }

    // Минуты назад (до 60 минут)
    if (difference.inMinutes < 60) {
      return l10n.timeMinutesAgo(difference.inMinutes);
    }

    // Часы назад (до 24 часов, но только сегодня)
    if (difference.inHours < 24 && time.day == now.day) {
      return l10n.timeHoursAgo(difference.inHours);
    }

    // Вчера
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (time.year == yesterday.year &&
        time.month == yesterday.month &&
        time.day == yesterday.day) {
      return l10n.timeYesterday;
    }

    // В течение последней недели - показываем день недели
    if (difference.inDays < 7) {
      final weekdayName = _getWeekdayName(context, time.weekday);
      return l10n.timeWeekday(weekdayName);
    }

    // Недели назад (до 4 недель)
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return l10n.timeWeeksAgo(weeks);
    }

    // Месяцы назад (до 12 месяцев)
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return l10n.timeMonthsAgo(months);
    }

    // Годы назад
    final years = (difference.inDays / 365).floor();
    return l10n.timeYearsAgo(years);
  }

  /// Получить локализованное название дня недели
  String _getWeekdayName(BuildContext context, int weekday) {
    final l10n = AppLocalizations.of(context)!;
    switch (weekday) {
      case DateTime.monday:
        return l10n.weekdayMonday;
      case DateTime.tuesday:
        return l10n.weekdayTuesday;
      case DateTime.wednesday:
        return l10n.weekdayWednesday;
      case DateTime.thursday:
        return l10n.weekdayThursday;
      case DateTime.friday:
        return l10n.weekdayFriday;
      case DateTime.saturday:
        return l10n.weekdaySaturday;
      case DateTime.sunday:
        return l10n.weekdaySunday;
      default:
        return '';
    }
  }

  void _handleNotificationTap(BuildContext context) async {
    debugPrint('🔔 Notification tapped: label=${notification.label}, title=${notification.title}');
    
    // Сначала выполняем навигацию (до любых изменений состояния)
    debugPrint('🧭 Navigating to destination for label: ${notification.label}');
    final didNavigate = await _navigateToDestination(context);
    debugPrint('✅ Navigation completed: $didNavigate');
    
    // Только после возврата с экрана отмечаем как прочитанное и обновляем
    if (!context.mounted) return;
    
    // Отмечаем как прочитанное если еще не прочитано
    if (!notification.isRead) {
      context
          .read<NotificationBloc>()
          .add(NotificatioIsReadFetch(id: notification.id));

      // Уменьшаем badge count
      await NotificationServices.instance.decrementBadge();
    }

    // Обновляем страницу при возврате
    if (context.mounted) {
      onNavigationReturn();
    }
  }

  /// Выполняет навигацию на соответствующий экран.
  /// Возвращает true если навигация была выполнена, false если нет.
  Future<bool> _navigateToDestination(BuildContext context) async {
    final labelType = _getNotificationLabelType(notification.label);
    debugPrint('🏷️ Label type resolved: $labelType (from label: ${notification.label})');
    
    // Проверяем context перед навигацией
    if (!context.mounted) {
      debugPrint('❌ Context not mounted, skipping navigation');
      return false;
    }
    
    // Получаем navigator
    final navigator = Navigator.of(context);

    try {
      switch (labelType) {
        case NotificationLabelType.gift:
          // Подарки → Страница подарков
          debugPrint('🎁 Opening gifts page...');
          await navigator.push(
            SlideRightRoute(page: const MyGifts()),
          );
          return true;
          
        case NotificationLabelType.bonus:
        case NotificationLabelType.birthday:
        case NotificationLabelType.loyalty:
          // Бонусы, ДР, лояльность → Профиль, вкладка "Бонусы"
          debugPrint('💰 Opening profile with bonus tab...');
          await navigator.push(
            SlideRightRoute(page: const ProfilePage(showBonusTab: true)),
          );
          return true;
          
        case NotificationLabelType.news:
          // Новости → Детальная страница новости или список
          if (notification.sourceId != null) {
            debugPrint('📰 Opening news detail page...');
            await navigator.push(
              NewsDetailPageRoute(
                newsId: notification.sourceId!,
                newsTitle: notification.body,
              ),
            );
            return true;
          }
          debugPrint('📰 News without sourceId, staying on notifications');
          return false;
          
        case NotificationLabelType.certificate:
          // Сертификаты → Страница сертификатов
          debugPrint('🎫 Opening certificate page...');
          await navigator.push(
            SlideRightRoute(page: const CertificatePage()),
          );
          return true;
          
        case NotificationLabelType.discount:
        case NotificationLabelType.promo:
        case NotificationLabelType.referral:
          // Скидки, промокоды, реферальная программа → Страница скидок
          debugPrint('🏷️ Opening discount page...');
          await navigator.push(
            SlideRightRoute(page: const DiscountPage()),
          );
          return true;
          
        case NotificationLabelType.info:
        case NotificationLabelType.reminder:
        case NotificationLabelType.system:
        case NotificationLabelType.test:
        case NotificationLabelType.customPush:
          // Информационные и системные уведомления — без навигации
          debugPrint('ℹ️ Info/System notification, no navigation needed');
          return false;
      }
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      return false;
    }
  }

  /// Метод для преобразования строки в enum
  NotificationLabelType _getNotificationLabelType(String? label) {
    if (label == null || label.isEmpty) return NotificationLabelType.info;

    switch (label.toLowerCase()) {
      // Подарки
      case 'gift':
      case 'gifts':
      case 'new_gift':
      case 'gift_received':
      case 'gift_issuance':
      case 'pending_gift':
      case 'lottery':
        return NotificationLabelType.gift;
      
      // Бонусы
      case 'bonus':
      case 'bonuses':
        return NotificationLabelType.bonus;
      
      // День рождения
      case 'birthday':
        return NotificationLabelType.birthday;
      
      // Лояльность
      case 'loyalty':
      case 'loyalty_level_up':
        return NotificationLabelType.loyalty;
      
      // Новости
      case 'news':
        return NotificationLabelType.news;
      
      // Сертификаты
      case 'certificate':
      case 'certificates':
        return NotificationLabelType.certificate;
      
      // Скидки
      case 'discount':
      case 'discounts':
        return NotificationLabelType.discount;
      
      // Промокоды
      case 'promo':
      case 'promo_code':
      case 'promocode':
        return NotificationLabelType.promo;
      
      // Реферальная программа
      case 'referral':
      case 'referral_applied':
        return NotificationLabelType.referral;
      
      // Информационные
      case 'info':
      case 'information':
        return NotificationLabelType.info;
      
      // Напоминания
      case 'reminder':
        return NotificationLabelType.reminder;
      
      // Системные
      case 'system':
        return NotificationLabelType.system;
      
      // Тестовые
      case 'test':
        return NotificationLabelType.test;
      
      // Кастомные push
      case 'custom_push':
      case 'broadcast':
      case 'promotion':
        return NotificationLabelType.customPush;
      
      default:
        // По умолчанию — информационное уведомление
        return NotificationLabelType.info;
    }
  }
}
