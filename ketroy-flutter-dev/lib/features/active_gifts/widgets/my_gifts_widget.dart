import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/features/my_gifts/domain/entities/gifts_entities.dart';
import 'package:ketroy_app/features/my_gifts/presentation/pages/gift_issuance_scanner.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

/// Виджет для отображения карточки подарка
class MyGiftsWidget extends StatelessWidget {
  final GiftsEntities gift;
  final VoidCallback? onIssuanceComplete;
  
  const MyGiftsWidget({
    super.key, 
    required this.gift,
    this.onIssuanceComplete,
  });

  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Изображение подарка с загрузкой
              _buildGiftImage(),
              SizedBox(width: 16.w),
              
              // Информация о подарке
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название подарка
                    Text(
                      gift.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Описание (если есть)
                    if (gift.description != null && gift.description!.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        gift.description!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    SizedBox(height: 12.h),
                    
                    // Статус подарка
                    _buildStatusBadge(l10n),
                  ],
                ),
              ),
            ],
          ),
          
          // Кнопка получения для выбранных подарков
          if (gift.isSelected) ...[
            SizedBox(height: 16.h),
            _buildGetGiftButton(context),
          ],
        ],
      ),
    );
  }
  
  /// Кнопка "Получить подарок" для выбранных подарков
  Widget _buildGetGiftButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () async {
        final result = await showGiftIssuanceScannerSheet(context, gift);
        if (result == true && onIssuanceComplete != null) {
          onIssuanceComplete!();
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_lightGreen, _primaryGreen],
          ),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 20.w,
            ),
            SizedBox(width: 10.w),
            Text(
              l10n.getAtStore,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Изображение подарка с индикатором загрузки
  Widget _buildGiftImage() {
    return Container(
      width: 100.w,
      height: 100.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F0),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: gift.image != null
            ? Image.network(
                gift.image!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildImagePlaceholder(
                    progress: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  );
                },
                errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  /// Placeholder для изображения с опциональным прогрессом загрузки
  Widget _buildImagePlaceholder({double? progress}) {
    return Container(
      color: const Color(0xFFF5F7F0),
      child: Center(
        child: progress != null
            ? SizedBox(
                width: 32.w,
                height: 32.w,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.5,
                  valueColor: const AlwaysStoppedAnimation<Color>(_primaryGreen),
                  backgroundColor: _primaryGreen.withValues(alpha: 0.2),
                ),
              )
            : Image.asset(
                'images/giftR.png',
                width: 48.w,
                height: 48.w,
                fit: BoxFit.contain,
                color: _primaryGreen.withValues(alpha: 0.4),
                colorBlendMode: BlendMode.srcIn,
              ),
      ),
    );
  }

  /// Бейдж статуса подарка
  Widget _buildStatusBadge(AppLocalizations l10n) {
    final (String text, Color bgColor, Color textColor, IconData icon) = _getStatusInfo(l10n);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.w,
            color: textColor,
          ),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Получить информацию о статусе
  (String, Color, Color, IconData) _getStatusInfo(AppLocalizations l10n) {
    switch (gift.status) {
      case GiftsEntities.statusPending:
        return (
          l10n.giftStatusPending,
          Colors.orange.withValues(alpha: 0.15),
          Colors.orange.shade700,
          Icons.hourglass_empty_rounded,
        );
      case GiftsEntities.statusSelected:
        return (
          l10n.giftStatusSelected,
          _accentGreen.withValues(alpha: 0.15),
          _lightGreen,
          Icons.check_circle_outline_rounded,
        );
      case GiftsEntities.statusActivated:
        return (
          l10n.giftStatusActivated,
          Colors.blue.withValues(alpha: 0.15),
          Colors.blue.shade700,
          Icons.verified_rounded,
        );
      case GiftsEntities.statusIssued:
        return (
          l10n.giftStatusIssued,
          _primaryGreen.withValues(alpha: 0.15),
          _primaryGreen,
          Icons.card_giftcard_rounded,
        );
      default:
        // Если статус не указан, показываем как полученный
        return (
          l10n.giftStatusReceived,
          _accentGreen.withValues(alpha: 0.15),
          _lightGreen,
          Icons.card_giftcard_rounded,
        );
    }
  }
}
