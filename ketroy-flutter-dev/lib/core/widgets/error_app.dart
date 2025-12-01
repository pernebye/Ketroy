// Экран ошибки инициализации приложения - стилизованный под дизайн Ketroy
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

/// Виджет экрана критической ошибки инициализации приложения
/// Используется когда приложение не может запуститься
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  // Константы дизайна Ketroy (дублируем, т.к. AppTheme может быть недоступен)
  static const String fontFamily = 'Gilroy';
  static const List<String> fontFamilyFallback = ['NotoSans', 'Roboto', 'sans-serif'];
  static const Color brandColor = Color(0xFF3C4B1B);
  static const Color darkBg = Color(0xFF1A1F12);
  static const Color lightGreen = Color(0xFF5A6F2B);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              darkBg,
              brandColor,
              lightGreen,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Иконка ошибки
                _buildErrorIcon(),
                
                SizedBox(height: 32.h),
                
                // Заголовок
                Text(
                  l10n?.appInitError ?? 'Ошибка инициализации',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontFamilyFallback: fontFamilyFallback,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 12.h),
                
                // Описание ошибки
                Text(
                  _getErrorDescription(error),
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontFamilyFallback: fontFamilyFallback,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 48.h),
                
                // Кнопка закрыть
                _buildCloseButton(context, l10n),
                
                SizedBox(height: 16.h),
                
                // Дополнительный текст
                Text(
                  'Попробуйте перезапустить приложение',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontFamilyFallback: fontFamilyFallback,
                    fontSize: 14.sp,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getErrorDescription(String error) {
    // Упрощаем технические ошибки для пользователя
    if (error.toLowerCase().contains('network') || 
        error.toLowerCase().contains('connection') ||
        error.toLowerCase().contains('socket')) {
      return 'Не удалось подключиться к серверу.\nПроверьте подключение к интернету.';
    }
    if (error.toLowerCase().contains('timeout')) {
      return 'Превышено время ожидания.\nПопробуйте позже.';
    }
    if (error.length > 100) {
      return '${error.substring(0, 100)}...';
    }
    return error;
  }

  Widget _buildErrorIcon() {
    return Container(
      width: 120.w,
      height: 120.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Icon(
              Icons.warning_amber_rounded,
              size: 48.sp,
              color: const Color(0xFFFFB74D),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, AppLocalizations? l10n) {
    return GestureDetector(
      onTap: () => SystemNavigator.pop(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: Colors.white.withValues(alpha: 0.15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 22.sp,
            ),
            SizedBox(width: 10.w),
            Text(
              l10n?.closeApp ?? 'Закрыть приложение',
              style: TextStyle(
                fontFamily: fontFamily,
                fontFamilyFallback: fontFamilyFallback,
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
