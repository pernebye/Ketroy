import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

/// Диалог подтверждения удаления аккаунта с предупреждением
class DeleteAccountConfirmDialog extends StatefulWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const DeleteAccountConfirmDialog({
    super.key,
    this.onConfirm,
    this.onCancel,
  });

  /// Показать диалог и вернуть результат
  static Future<bool> show(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.transparent,
          builder: (dialogContext) => DeleteAccountConfirmDialog(
            onConfirm: () => Navigator.of(dialogContext).pop(true),
            onCancel: () => Navigator.of(dialogContext).pop(false),
          ),
        ) ??
        false;
  }

  @override
  State<DeleteAccountConfirmDialog> createState() =>
      _DeleteAccountConfirmDialogState();
}

class _DeleteAccountConfirmDialogState extends State<DeleteAccountConfirmDialog>
    with SingleTickerProviderStateMixin {
  // Фирменные цвета Ketroy
  static const Color _primaryGreen = Color(0xFF3C4B1B);

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
                            horizontal: 28.w, vertical: 32.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.15),
                              blurRadius: 40,
                              spreadRadius: 0,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Иконка предупреждения
                            Container(
                              width: 56.w,
                              height: 56.w,
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 28.sp,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            // Заголовок
                            Text(
                              l10n?.deleteAccountConfirm ?? 'Delete account?',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16.h),
                            // Предупреждение
                            Text(
                              l10n?.deleteAccountWarning ??
                                  'By deleting your account, you will lose access to all personal data, including bonuses and special offers. Re-registration will remain available at any time.',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.black54,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 28.h),
                            // Кнопки
                            Row(
                              children: [
                                // Кнопка "Удалить" - красная
                                Expanded(
                                  child: _buildDeleteButton(
                                    l10n?.delete ?? 'Delete',
                                    () => _handleClose(true),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                // Кнопка "Отмена" - нейтральная, чтобы пользователь мог передумать
                                Expanded(
                                  child: _buildCancelButton(
                                    l10n?.cancel ?? 'Cancel',
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

  Widget _buildDeleteButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: Colors.red.shade700,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCancelButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryGreen.withValues(alpha: 0.9),
              _primaryGreen,
            ],
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
}


