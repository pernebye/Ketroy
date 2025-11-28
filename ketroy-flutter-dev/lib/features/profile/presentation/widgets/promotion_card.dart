import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/features/profile/data/promotion_model.dart';
import 'package:ketroy_app/features/profile/presentation/widgets/promotion_detail_sheet.dart';

/// Компактная карточка акции для горизонтального скроллинга
class PromotionCard extends StatelessWidget {
  final PromotionModel promotion;

  const PromotionCard({super.key, required this.promotion});

  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPromotionDetails(context),
      child: Container(
        width: 160.w,
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Иконка типа акции с градиентом
            Container(
              height: 70.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
                gradient: _getTypeGradient(),
              ),
              child: Stack(
                children: [
                  // Декоративные элементы
                  Positioned(
                    right: -10.w,
                    top: -10.h,
                    child: Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -5.w,
                    bottom: -15.h,
                    child: Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  // Иконка по центру
                  Center(
                    child: Text(
                      promotion.typeIcon,
                      style: TextStyle(fontSize: 32.sp),
                    ),
                  ),
                  // Бейдж активности
                  if (promotion.isCurrentlyActive)
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accentGreen,
                          boxShadow: [
                            BoxShadow(
                              color: _accentGreen.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Контент
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название акции
                    Text(
                      promotion.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    // Тип акции
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        _getShortTypeName(),
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w500,
                          color: _primaryGreen,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Описание или даты
                    if (promotion.description != null &&
                        promotion.description!.isNotEmpty)
                      Text(
                        promotion.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.black54,
                          height: 1.2,
                        ),
                      )
                    else if (promotion.endDate != null)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 10.sp,
                            color: Colors.black38,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'до ${_formatDate(promotion.endDate!)}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.black38,
                            ),
                          ),
                        ],
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

  String _getShortTypeName() {
    switch (promotion.type) {
      case 'single_purchase':
        return 'Покупка';
      case 'friend_discount':
        return 'Для друга';
      case 'date_based':
        return 'Ограничено';
      case 'birthday':
        return 'ДР';
      case 'lottery':
        return 'Лотерея';
      default:
        return 'Акция';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  void _showPromotionDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => PromotionDetailSheet(promotion: promotion),
    );
  }
}

