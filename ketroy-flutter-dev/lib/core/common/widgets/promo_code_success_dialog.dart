import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:ketroy_app/features/discount/domain/repository/discount_repository.dart';
import 'package:ketroy_app/features/discount/domain/entities/referral_info.dart';

/// Диалог успешного применения промокода
/// Показывается автоматически при переходе по реферальной ссылке
class PromoCodeSuccessDialog extends StatefulWidget {
  final String promoCode;
  final String? ownerName;
  final int? discountPercent;
  final int? bonusPercent;
  final int? bonusPurchases;
  final VoidCallback? onDismiss;

  const PromoCodeSuccessDialog({
    super.key,
    required this.promoCode,
    this.ownerName,
    this.discountPercent,
    this.bonusPercent,
    this.bonusPurchases,
    this.onDismiss,
  });

  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);

  /// Показать диалог успешного применения промокода
  /// Автоматически загружает условия реферальной программы с бэкенда
  static Future<void> show(
    BuildContext context, {
    required String promoCode,
    String? ownerName,
    int? discountPercent,
    int? bonusPercent,
    int? bonusPurchases,
    VoidCallback? onDismiss,
  }) async {
    // Загружаем условия реферальной программы с бэкенда
    ReferralInfo? referralInfo;
    try {
      final discountRepository = serviceLocator<DiscountRepository>();
      final result = await discountRepository.getReferralInfo();
      result.fold(
        (failure) => debugPrint('⚠️ Failed to load referral info: ${failure.message}'),
        (info) => referralInfo = info,
      );
    } catch (e) {
      debugPrint('⚠️ Error loading referral info: $e');
    }

    // Используем данные с бэкенда если они есть, иначе fallback на переданные параметры
    final finalDiscountPercent = referralInfo?.newUserDiscountPercent ?? discountPercent;
    final finalBonusPercent = referralInfo?.newUserBonusPercent ?? bonusPercent;
    final finalBonusPurchases = referralInfo?.newUserBonusPurchases ?? bonusPurchases;

    if (!context.mounted) return;

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Promo Code Success',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return PromoCodeSuccessDialog(
          promoCode: promoCode,
          ownerName: ownerName,
          discountPercent: finalDiscountPercent,
          bonusPercent: finalBonusPercent,
          bonusPurchases: finalBonusPurchases,
          onDismiss: onDismiss,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: curvedAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<PromoCodeSuccessDialog> createState() => _PromoCodeSuccessDialogState();
}

class _PromoCodeSuccessDialogState extends State<PromoCodeSuccessDialog> {
  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 32.w),
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Анимированная иконка успеха
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_accentGreen, _primaryGreen],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _accentGreen.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.celebration_rounded,
                    color: Colors.white,
                    size: 42.w,
                  ),
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Заголовок
              Text(
                l10n.promocodeApplied,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 12.h),
              
              // Промокод
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: _accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _accentGreen.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_offer_rounded,
                      color: _primaryGreen,
                      size: 20.w,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      widget.promoCode,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: _primaryGreen,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20.h),
              
              // Что вы получили - условия из бэкенда
              _buildBenefitsSection(l10n),
              
              // Показываем имя владельца промокода если есть
              if (widget.ownerName != null && widget.ownerName!.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Text(
                  '${l10n.promoCodeFrom}: ${widget.ownerName}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black45,
                  ),
                ),
              ],
              
              SizedBox(height: 24.h),
              
              // Кнопка закрытия
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onDismiss?.call();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_lightGreen, _primaryGreen],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        l10n.great,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Секция с полученными бонусами
  Widget _buildBenefitsSection(AppLocalizations l10n) {
    final discountPercent = widget.discountPercent;
    final bonusPercent = widget.bonusPercent;
    final bonusPurchases = widget.bonusPurchases;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _accentGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _accentGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок секции
          Row(
            children: [
              Icon(
                Icons.card_giftcard_rounded,
                color: _accentGreen,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                l10n.youReceived,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: _primaryGreen,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // Персональная скидка
          if (discountPercent != null && discountPercent > 0)
            _buildBenefitItem(
              icon: Icons.percent_rounded,
              text: l10n.personalDiscountBenefit(discountPercent),
            ),
          
          // Бонусы с покупок
          if (bonusPercent != null && bonusPercent > 0 && bonusPurchases != null) ...[
            SizedBox(height: 8.h),
            _buildBenefitItem(
              icon: Icons.stars_rounded,
              text: l10n.bonusFromPurchasesBenefit(bonusPercent, bonusPurchases, _getPluralPurchases(bonusPurchases, l10n)),
            ),
          ],
        ],
      ),
    );
  }

  /// Элемент бонуса
  Widget _buildBenefitItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: _primaryGreen,
          size: 18.w,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// Склонение слова "покупка"
  String _getPluralPurchases(int count, AppLocalizations l10n) {
    if (count == 1) return l10n.purchaseSingular;
    if (count >= 2 && count <= 4) return l10n.purchaseFew;
    return l10n.purchaseMany;
  }
}
