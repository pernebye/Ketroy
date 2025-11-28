import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/features/auth/presentation/pages/login_page.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

/// Люксовый диалог для требования авторизации в стиле Ketroy
class AuthRequiredDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onCancel;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onAfterLogin;

  /// Если true - диалог показан через showDialog и при закрытии нужен Navigator.pop()
  /// Если false - диалог используется как виджет (overlay) и закрытие через callback
  final bool isModal;

  const AuthRequiredDialog({
    super.key,
    this.title = 'Authorization Required',
    this.message = 'To access information about yourself, discounts, gifts and other bonuses — you need to register!',
    this.onCancel,
    this.onLoginPressed,
    this.onAfterLogin,
    this.isModal = false,
  });

  /// Показать диалог
  static Future<void> show(
    BuildContext context, {
    String? title,
    String? message,
  }) {
    final l10n = AppLocalizations.of(context);
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => AuthRequiredDialog(
        title: title ?? l10n?.authRequired ?? 'Authorization Required',
        message: message ?? l10n?.authRequiredMessage ?? 'To access information about yourself, discounts, gifts and other bonuses — you need to register!',
        isModal: true,
      ),
    );
  }

  void _handleLogin(BuildContext context) {
    // Сначала вызываем callback для закрытия overlay (если используется как виджет)
    onLoginPressed?.call();

    // Если диалог модальный (показан через showDialog) - закрываем его
    if (isModal) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Переходим на страницу авторизации
    Navigator.of(context, rootNavigator: true)
        .push(
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    )
        .then((_) {
      onAfterLogin?.call();
    });
  }

  void _handleCancel(BuildContext context) {
    if (isModal) {
      Navigator.pop(context);
    }
    onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Элегантный размытый фон
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _handleCancel(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          // Контент диалога
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 40,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Минималистичная иконка
                    Container(
                      width: 72.w,
                      height: 72.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F8F8),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.black,
                          size: 28.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 28.h),
                    // Заголовок - элегантная типографика
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: 2.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),
                    // Тонкая разделительная линия
                    Container(
                      width: 40.w,
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                    SizedBox(height: 20.h),
                    // Сообщение
                    Text(
                      message,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF666666),
                        height: 1.5,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 36.h),
                    // Кнопка "Войти" - строгий чёрный стиль
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Column(
                          children: [
                            _buildPrimaryButton(
                              context,
                              l10n?.loginToAccount ?? 'Log In',
                              () => _handleLogin(context),
                            ),
                            SizedBox(height: 12.h),
                            // Кнопка "Отмена" - минималистичная
                            _buildSecondaryButton(
                              context,
                              l10n?.cancel ?? 'Cancel',
                              () => _handleCancel(context),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF666666),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
