import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/features/profile/domain/entities/discount_entity.dart';
import 'package:ketroy_app/features/profile/presentation/pages/qr_scanner_sheet.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

/// Анимированный счётчик для бонусов с эффектом "перебегания"
class AnimatedBonusCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedBonusCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<AnimatedBonusCounter> createState() => _AnimatedBonusCounterState();
}

class _AnimatedBonusCounterState extends State<AnimatedBonusCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousValue = 0;
  int _currentValue = 0;
  bool _isIncreasing = true;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _previousValue = widget.value;
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(AnimatedBonusCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _currentValue = widget.value;
      _isIncreasing = widget.value > oldWidget.value;
      _controller.forward(from: 0);
      debugPrint('💰 Bonus animation: $_previousValue → $_currentValue (${_isIncreasing ? "+" : "-"})');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Интерполируем значение для плавного счётчика
        final displayValue = (_previousValue + 
            ((_currentValue - _previousValue) * _animation.value)).round();
        
        // Эффект масштаба: увеличивается при начислении, уменьшается при списании
        final scaleEffect = _controller.isAnimating 
            ? 0.15 * (1 - (_animation.value - 0.3).abs() * 1.5).clamp(0.0, 1.0)
            : 0.0;
        final scale = _isIncreasing ? 1.0 + scaleEffect : 1.0 - scaleEffect * 0.5;
        
        // Эффект подсветки: зелёный при начислении, красный при списании
        Color? glowColor;
        if (_controller.isAnimating && _animation.value < 0.7) {
          final glowOpacity = (1 - _animation.value / 0.7) * 0.6;
          glowColor = _isIncreasing 
              ? const Color(0xFF8BC34A).withValues(alpha: glowOpacity)
              : const Color(0xFFE57373).withValues(alpha: glowOpacity);
        }
            
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: glowColor != null ? BoxDecoration(
              borderRadius: BorderRadius.circular(4.r),
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ) : null,
            child: Text(
              displayValue.toString(),
              style: widget.style,
            ),
          ),
        );
      },
    );
  }
}

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
        // Бонусы с анимированным счётчиком
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
              Row(
                children: [
                  AnimatedBonusCounter(
                    value: int.tryParse(widget.bonus) ?? 0,
                    style: TextStyle(fontSize: 17.sp, color: Colors.white),
                    duration: const Duration(milliseconds: 1200),
                  ),
                  Text(
                    ' ${l10n.tg}',
                    style: TextStyle(fontSize: 17.sp, color: Colors.white),
                  ),
                ],
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
