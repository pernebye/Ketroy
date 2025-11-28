import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/features/lottery/data/lottery_data_source.dart';
import 'package:ketroy_app/features/my_gifts/data/data_source/gift_data_source.dart';

/// Модальное окно лотереи с анимацией появления снизу
class LotteryModal extends StatefulWidget {
  final LotteryData lotteryData;
  final VoidCallback onDismiss;
  final Function(String giftGroupId, List<GiftOption> gifts) onClaimSuccess;

  const LotteryModal({
    super.key,
    required this.lotteryData,
    required this.onDismiss,
    required this.onClaimSuccess,
  });

  @override
  State<LotteryModal> createState() => _LotteryModalState();

  /// Показать модальное окно лотереи
  static Future<void> show({
    required BuildContext context,
    required LotteryData lotteryData,
    required VoidCallback onDismiss,
    required Function(String giftGroupId, List<GiftOption> gifts) onClaimSuccess,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return LotteryModal(
          lotteryData: lotteryData,
          onDismiss: onDismiss,
          onClaimSuccess: onClaimSuccess,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ));

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}

class _LotteryModalState extends State<LotteryModal>
    with SingleTickerProviderStateMixin {
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isLoading = false;
  final LotteryDataSourceImpl _lotteryDataSource = LotteryDataSourceImpl();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _claimGift() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final result = await _lotteryDataSource.claimLotteryGift(
        widget.lotteryData.promotionId,
      );

      if (!mounted) return;

      if (result.success && result.giftGroupId != null) {
        Navigator.of(context).pop();
        widget.onClaimSuccess(result.giftGroupId!, result.gifts);
      } else if (result.giftAlreadyClaimed) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы уже получили подарок. Найдите его в разделе "Мои подарки"'),
            backgroundColor: _primaryGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Произошла ошибка. Попробуйте позже'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _dismiss() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w),
            constraints: BoxConstraints(maxWidth: 380.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Кнопка закрытия
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      margin: EdgeInsets.only(bottom: 16.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22.w,
                      ),
                    ),
                  ),
                ),

                // Основная карточка
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28.r),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Верхняя часть с градиентом
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 28.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_lightGreen, _primaryGreen],
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28.r),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Анимированная иконка подарка
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 90.w,
                                    height: 90.w,
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _accentGreen.withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'images/giftR.png',
                                      fit: BoxFit.contain,
                                      color: Colors.white,
                                      colorBlendMode: BlendMode.srcIn,
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 20.h),
                            
                            // Заголовок
                            Text(
                              widget.lotteryData.modalTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Нижняя часть с контентом
                      Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          children: [
                            // Изображение (если есть)
                            if (widget.lotteryData.modalImage != null)
                              Container(
                                margin: EdgeInsets.only(bottom: 20.h),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16.r),
                                  child: Image.network(
                                    widget.lotteryData.modalImage!,
                                    width: double.infinity,
                                    height: 150.h,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                  ),
                                ),
                              ),

                            // Текст
                            Text(
                              widget.lotteryData.modalText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: Colors.black54,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 8.h),

                            // Количество подарков
                            if (widget.lotteryData.giftsCount > 1)
                              Container(
                                margin: EdgeInsets.only(bottom: 20.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: _accentGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  '🎁 ${widget.lotteryData.giftsCount} подарков на выбор',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryGreen,
                                  ),
                                ),
                              ),

                            SizedBox(height: 16.h),

                            // Кнопка получения подарка
                            GestureDetector(
                              onTap: _isLoading ? null : _claimGift,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_lightGreen, _primaryGreen],
                                  ),
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryGreen.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 24.w,
                                          height: 24.w,
                                          child: const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.card_giftcard_rounded,
                                              color: Colors.white,
                                              size: 22.w,
                                            ),
                                            SizedBox(width: 10.w),
                                            Text(
                                              widget.lotteryData.modalButtonText,
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),

                            SizedBox(height: 12.h),

                            // Текст "позже"
                            GestureDetector(
                              onTap: _dismiss,
                              child: Text(
                                'Позже',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.black38,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

