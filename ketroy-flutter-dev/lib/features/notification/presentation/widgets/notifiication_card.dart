import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ketroy_app/features/bonus/presentation/pages/bonus_page.dart';
import 'package:ketroy_app/features/certificates/presentation/pages/certificate_page.dart';
import 'package:ketroy_app/features/discount/presentation/pages/discount_page.dart';
import 'package:ketroy_app/features/my_gifts/presentation/pages/gifts_page.dart';
import 'package:ketroy_app/features/news/presentation/pages/news_page_detail.dart';
import 'package:ketroy_app/features/notification/domain/entities/notification_entity.dart';
import 'package:ketroy_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:ketroy_app/services/notification_services.dart';

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

            // === Время ===
            Text(
              _formatTimeOnly(notification.createdAt),
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
        // Золотая монета тенге для списания/начисления бонусов
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
        // Чёрная бирка скидки
        imagePath = 'images/notif_discount.png';
        break;
      case NotificationLabelType.news:
      case NotificationLabelType.info:
      case NotificationLabelType.reminder:
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
        icon = Icons.local_offer_rounded;
        color = const Color(0xFF212121);
        bgColor = const Color(0xFFF5F5F5);
        break;
      case NotificationLabelType.news:
      case NotificationLabelType.info:
      case NotificationLabelType.reminder:
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

  /// Форматирование времени (только часы:минуты)
  String _formatTimeOnly(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  void _handleNotificationTap(BuildContext context) async {
    // Отмечаем как прочитанное если еще не прочитано
    if (!notification.isRead) {
      context
          .read<NotificationBloc>()
          .add(NotificatioIsReadFetch(id: notification.id));

      // Уменьшаем badge count
      await NotificationServices.instance.decrementBadge();
      if (!context.mounted) {
        return;
      }
    }

    // Выполняем навигацию и ждем возврата
    await _navigateToDestination(context);

    // Обновляем страницу при возврате
    onNavigationReturn();
  }

  Future<void> _navigateToDestination(BuildContext context) async {
    final labelType = _getNotificationLabelType(notification.label);

    switch (labelType) {
      case NotificationLabelType.gift:
        await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (context) => const GiftsPage()),
        );
        break;
      case NotificationLabelType.bonus:
        await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (context) => const BonusPage()),
        );
        break;
      case NotificationLabelType.news:
        if (notification.sourceId != null) {
          await Navigator.of(context, rootNavigator: true).push(
            NewsDetailPageRoute(
              newsId: notification.sourceId!,
              newsTitle: notification.body,
            ),
          );
        }
        break;
      case NotificationLabelType.certificate:
        await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (context) => const CertificatePage()),
        );
        break;
      case NotificationLabelType.discount:
      case NotificationLabelType.promo:
        await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (context) => const DiscountPage()),
        );
        break;
      case NotificationLabelType.info:
      case NotificationLabelType.reminder:
      case NotificationLabelType.system:
      case NotificationLabelType.test:
        // Просто помечаем как прочитанное без навигации
        break;
    }
  }

  /// Метод для преобразования строки в enum
  NotificationLabelType _getNotificationLabelType(String? label) {
    if (label == null) return NotificationLabelType.news;

    switch (label.toLowerCase()) {
      case 'gift':
        return NotificationLabelType.gift;
      case 'bonus':
        return NotificationLabelType.bonus;
      case 'news':
        return NotificationLabelType.news;
      case 'certificate':
        return NotificationLabelType.certificate;
      case 'discount':
        return NotificationLabelType.discount;
      case 'promo':
        return NotificationLabelType.promo;
      case 'info':
        return NotificationLabelType.info;
      case 'reminder':
        return NotificationLabelType.reminder;
      case 'system':
        return NotificationLabelType.system;
      case 'test':
        return NotificationLabelType.test;
      default:
        return NotificationLabelType.news;
    }
  }
}
