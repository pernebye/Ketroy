import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/features/profile/domain/entities/discount_entity.dart';
import 'package:ketroy_app/features/profile/presentation/pages/qr_scanner_sheet.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

class BonusCardWidget extends StatefulWidget {
  const BonusCardWidget({
    super.key,
    required this.qrButton,
    this.discount,
    required this.bonus,
    this.onRefresh,
  });

  final bool qrButton;
  final DiscountEntity? discount;
  final String bonus;
  final VoidCallback? onRefresh;

  @override
  State<BonusCardWidget> createState() => _BonusCardWidgetState();
}

class _BonusCardWidgetState extends State<BonusCardWidget> {
  Future<void> _navigateToQRPage(BuildContext context) async {
    final result = await showQrScannerSheet(context);

    // ✅ Если успешно отсканировали, обновляем данные
    if (result == true) {
      debugPrint('🔄 QR scanned successfully, refreshing...');
      // Небольшая задержка чтобы данные успели сохраниться
      await Future.delayed(const Duration(milliseconds: 300));
      widget.onRefresh?.call();
    }
  }

  // Цвета
  static const Color _primaryGreen = Color(0xFF3C4B1B);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        // Карточка
        SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Image.asset(
            'images/bonus_card.png',
          ),
        ),
        // Текст скидки или замочек
        Positioned(
          left: 24.w,
          top: 28.h,
          child: GestureDetector(
            onTap: widget.discount == null ? () => _navigateToQRPage(context) : null,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: widget.discount != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.discount?.discount ?? 0}%',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          l10n.discount,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          l10n.scanQr,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        // Бонусы
        Positioned(
          left: 30.w,
          bottom: 30.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.bonuses,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${widget.bonus} ${l10n.tg}',
                style: TextStyle(fontSize: 17.sp, color: Colors.white),
              ),
            ],
          ),
        ),
        // QR кнопка в правом нижнем углу
        if (widget.qrButton)
          Positioned(
            right: 28.w,
            bottom: 28.h,
            child: GestureDetector(
              onTap: () => _navigateToQRPage(context),
              child: Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: _primaryGreen,
                    size: 28.w,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
