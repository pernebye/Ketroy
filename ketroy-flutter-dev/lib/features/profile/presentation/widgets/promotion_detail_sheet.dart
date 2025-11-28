import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/profile/data/promotion_model.dart';

/// Bottom Sheet с детальной информацией об акции
class PromotionDetailSheet extends StatelessWidget {
  final PromotionModel promotion;

  const PromotionDetailSheet({super.key, required this.promotion});

  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _cardBg = Color(0xFFF5F7F0);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28.r),
              topRight: Radius.circular(28.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Ручка для свайпа
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Контент
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(20.w),
                  children: [
                    _buildHeader(),
                    SizedBox(height: 20.h),
                    _buildMainInfo(),
                    SizedBox(height: 16.h),
                    if (promotion.description != null &&
                        promotion.description!.isNotEmpty) ...[
                      _buildDescription(),
                      SizedBox(height: 16.h),
                    ],
                    _buildPromotionDetails(),
                    SizedBox(height: 16.h),
                    if (promotion.gifts.isNotEmpty) ...[
                      _buildGiftsSection(),
                      SizedBox(height: 16.h),
                    ],
                    _buildDatesSection(),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Иконка типа
        Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            gradient: _getTypeGradient(),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              promotion.typeIcon,
              style: TextStyle(fontSize: 28.sp),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        // Название и тип
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                promotion.name,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  promotion.typeDisplayName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainInfo() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                promotion.isCurrentlyActive
                    ? Icons.check_circle_rounded
                    : Icons.pause_circle_rounded,
                color: promotion.isCurrentlyActive ? _accentGreen : Colors.orange,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                promotion.isCurrentlyActive ? 'Акция активна' : 'Акция неактивна',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: promotion.isCurrentlyActive ? _primaryGreen : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18.sp,
              color: _primaryGreen,
            ),
            SizedBox(width: 8.w),
            Text(
              'Описание',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: _primaryGreen,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Text(
            promotion.description!,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionDetails() {
    final details = _getPromotionDetails();
    if (details.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.settings_outlined,
              size: 18.sp,
              color: _primaryGreen,
            ),
            SizedBox(width: 8.w),
            Text(
              'Условия акции',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: _primaryGreen,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: details.map((detail) {
              return Padding(
                padding: EdgeInsets.only(bottom: detail != details.last ? 12.h : 0),
                child: Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: _accentGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        detail['icon'] as IconData,
                        size: 18.sp,
                        color: _primaryGreen,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail['label'] as String,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            detail['value'] as String,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getPromotionDetails() {
    final List<Map<String, dynamic>> details = [];

    // Минимальная сумма покупки
    if (promotion.minPurchaseAmount != null) {
      details.add({
        'icon': Icons.shopping_cart_outlined,
        'label': 'Минимальная сумма покупки',
        'value': '${_formatNumber(promotion.minPurchaseAmount!)} ₸',
      });
    }

    // Процент скидки
    if (promotion.discountPercent != null) {
      details.add({
        'icon': Icons.percent_rounded,
        'label': 'Скидка',
        'value': '${promotion.discountPercent}%',
      });
    }

    // Длительность
    if (promotion.durationDays != null) {
      details.add({
        'icon': Icons.timer_outlined,
        'label': 'Срок действия',
        'value': '${promotion.durationDays} дней',
      });
    }

    // Дни до дня рождения (для birthday)
    if (promotion.daysBefore != null) {
      details.add({
        'icon': Icons.cake_outlined,
        'label': 'Начало акции',
        'value': 'За ${promotion.daysBefore} дней до дня рождения',
      });
    }

    // Для лотереи - модальное окно
    if (promotion.type == 'lottery' || promotion.type == 'date_based') {
      if (promotion.modalTitle != null && promotion.modalTitle!.isNotEmpty) {
        details.add({
          'icon': Icons.celebration_outlined,
          'label': 'Заголовок',
          'value': promotion.modalTitle!,
        });
      }
      if (promotion.modalText != null && promotion.modalText!.isNotEmpty) {
        details.add({
          'icon': Icons.article_outlined,
          'label': 'Сообщение',
          'value': promotion.modalText!,
        });
      }
    }

    return details;
  }

  Widget _buildGiftsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.card_giftcard_rounded,
              size: 18.sp,
              color: _primaryGreen,
            ),
            SizedBox(width: 8.w),
            Text(
              'Подарки',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: _primaryGreen,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        SizedBox(
          height: 100.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: promotion.gifts.length,
            itemBuilder: (context, index) {
              final gift = promotion.gifts[index];
              final giftCatalog = gift.giftCatalog;
              
              return Container(
                width: 90.w,
                margin: EdgeInsets.only(right: 10.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (giftCatalog?.image != null && giftCatalog!.image!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: CachedNetworkImage(
                          imageUrl: giftCatalog.image!,
                          width: 50.w,
                          height: 50.w,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CompactLoader(),
                          errorWidget: (context, url, error) => Icon(
                            Icons.card_giftcard_rounded,
                            size: 30.sp,
                            color: _accentGreen,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.card_giftcard_rounded,
                        size: 30.sp,
                        color: _accentGreen,
                      ),
                    SizedBox(height: 6.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        giftCatalog?.name ?? 'Подарок',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDatesSection() {
    if (promotion.startDate == null && promotion.endDate == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          if (promotion.startDate != null)
            Expanded(
              child: _buildDateItem(
                icon: Icons.play_circle_outline_rounded,
                label: 'Начало',
                date: promotion.startDate!,
              ),
            ),
          if (promotion.startDate != null && promotion.endDate != null)
            Container(
              width: 1,
              height: 40.h,
              color: Colors.black.withValues(alpha: 0.1),
              margin: EdgeInsets.symmetric(horizontal: 16.w),
            ),
          if (promotion.endDate != null)
            Expanded(
              child: _buildDateItem(
                icon: Icons.stop_circle_outlined,
                label: 'Окончание',
                date: promotion.endDate!,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateItem({
    required IconData icon,
    required String label,
    required String date,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20.sp, color: _primaryGreen),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.black54,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          _formatDateFull(date),
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _formatDateFull(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
        'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
      ];
      return '${date.day} ${months[date.month]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  LinearGradient _getTypeGradient() {
    switch (promotion.type) {
      case 'single_purchase':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        );
      case 'friend_discount':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
        );
      case 'date_based':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        );
      case 'birthday':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFfa709a), Color(0xFFfee140)],
        );
      case 'lottery':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFa8edea), Color(0xFFfed6e3)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_lightGreen, _primaryGreen],
        );
    }
  }
}

