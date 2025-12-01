// Экран ошибки загрузки данных - стилизованный под дизайн Ketroy
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

class ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final bool isNetworkError;

  const ErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
    this.isNetworkError = true,
  });

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
              Color(0xFF1A1F12), // darkBg
              Color(0xFF3C4B1B), // primaryGreen
              Color(0xFF5A6F2B), // lightGreen
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
                  l10n?.dataLoadError ?? 'Ошибка загрузки данных',
                  style: AppTheme.textStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 12.h),
                
                // Подзаголовок
                Text(
                  isNetworkError 
                      ? (l10n?.checkInternet ?? 'Проверьте подключение к интернету')
                      : error,
                  style: AppTheme.textStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 48.h),
                
                // Кнопка повторить
                _buildRetryButton(context, l10n),
              ],
            ),
          ),
        ),
      ),
    );
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
            child: isNetworkError 
                ? _buildWifiOffIcon()
                : _buildErrorAlertIcon(),
          ),
        ),
      ),
    );
  }

  Widget _buildWifiOffIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // WiFi иконка
        Icon(
          Icons.wifi_rounded,
          size: 44.sp,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        // Перечеркивание
        Transform.rotate(
          angle: 0.785398, // 45 градусов
          child: Container(
            width: 56.w,
            height: 3.h,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B),
              borderRadius: BorderRadius.circular(2.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorAlertIcon() {
    return Icon(
      Icons.error_outline_rounded,
      size: 48.sp,
      color: const Color(0xFFFFB74D),
    );
  }

  Widget _buildRetryButton(BuildContext context, AppLocalizations? l10n) {
    return GlassMorphism(
      borderRadius: 16,
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
      onPressed: onRetry,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 22.sp,
          ),
          SizedBox(width: 10.w),
          Text(
            l10n?.retry ?? 'Повторить',
            style: AppTheme.textStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Компактный виджет ошибки для встраивания внутрь других экранов
/// Используется когда нужно показать ошибку без полноэкранного Scaffold
class ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final bool isCompact;
  final bool isNetworkError;

  const ErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
    this.isCompact = false,
    this.isNetworkError = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 16.w : 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка
            _buildIcon(),
            
            SizedBox(height: isCompact ? 16.h : 24.h),
            
            // Заголовок
            Text(
              l10n?.dataLoadError ?? 'Ошибка загрузки данных',
              style: AppTheme.textStyle(
                fontSize: isCompact ? 18.sp : 20.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 8.h),
            
            // Описание ошибки
            Text(
              isNetworkError 
                  ? (l10n?.checkInternet ?? 'Проверьте подключение к интернету')
                  : error,
              style: AppTheme.textStyle(
                fontSize: isCompact ? 14.sp : 15.sp,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: isCompact ? 20.h : 28.h),
            
            // Кнопка
            AppButton(
              title: l10n?.retry ?? 'Повторить',
              icon: Icons.refresh_rounded,
              backgroundColor: AppTheme.brandColor,
              textColor: Colors.white,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final iconSize = isCompact ? 64.w : 80.w;
    final innerSize = isCompact ? 44.w : 56.w;
    
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.brandColor.withValues(alpha: 0.1),
      ),
      child: Center(
        child: isNetworkError
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.wifi_rounded,
                    size: innerSize * 0.6,
                    color: AppTheme.brandColor.withValues(alpha: 0.7),
                  ),
                  Transform.rotate(
                    angle: 0.785398,
                    child: Container(
                      width: innerSize * 0.8,
                      height: 2.5.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE57373),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                ],
              )
            : Icon(
                Icons.error_outline_rounded,
                size: innerSize * 0.6,
                color: const Color(0xFFFF9800),
              ),
      ),
    );
  }
}
