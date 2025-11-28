import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

/// Люксовый диалог подтверждения выхода из аккаунта в стиле Ketroy
class LogoutConfirmDialog extends StatefulWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const LogoutConfirmDialog({
    super.key,
    this.onConfirm,
    this.onCancel,
  });

  /// Показать диалог и вернуть результат
  static Future<bool> show(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.transparent,
          builder: (dialogContext) => LogoutConfirmDialog(
            onConfirm: () => Navigator.of(dialogContext).pop(true),
            onCancel: () => Navigator.of(dialogContext).pop(false),
          ),
        ) ??
        false;
  }

  @override
  State<LogoutConfirmDialog> createState() => _LogoutConfirmDialogState();
}

class _LogoutConfirmDialogState extends State<LogoutConfirmDialog>
    with SingleTickerProviderStateMixin {
  // Фирменные цвета Ketroy
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _accentGreen = Color(0xFF8BC34A);

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleClose(bool result) async {
    await _animController.reverse();
    if (result) {
      widget.onConfirm?.call();
    } else {
      widget.onCancel?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Элегантный размытый фон
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => _handleClose(false),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 12 * _fadeAnimation.value,
                      sigmaY: 12 * _fadeAnimation.value,
                    ),
                    child: Container(
                      color: Colors.black
                          .withValues(alpha: 0.4 * _fadeAnimation.value),
                    ),
                  ),
                ),
              ),
              // Контент диалога
              Center(
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            horizontal: 32.w, vertical: 36.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryGreen.withValues(alpha: 0.15),
                              blurRadius: 40,
                              spreadRadius: 0,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Заголовок
                            Text(
                              l10n?.logoutConfirm ?? 'Log out from account?',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: _primaryGreen,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 28.h),
                            // Кнопки
                            Row(
                              children: [
                                // Кнопка "Да" - неяркая
                                Expanded(
                                  child: _buildSecondaryButton(
                                    l10n?.yes ?? 'Yes',
                                    () => _handleClose(true),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                // Кнопка "Нет" - яркая, чтобы пользователь остался
                                Expanded(
                                  child: _buildPrimaryButton(
                                    l10n?.no ?? 'No',
                                    () => _handleClose(false),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_accentGreen, _primaryGreen],
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
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7F0),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: _primaryGreen.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: _primaryGreen.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

