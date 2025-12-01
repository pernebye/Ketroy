import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/theme/theme.dart';

/// Брендовый лоадер Ketroy с оптимизированным размером и цветом
class Loader extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const Loader({
    super.key,
    this.size = 40.0,
    this.strokeWidth = 3.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppTheme.brandColor,
          ),
        ),
      ),
    );
  }
}

/// Компактный лоадер для использования внутри кнопок и небольших контейнеров
class CompactLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const CompactLoader({
    super.key,
    this.size = 20.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppTheme.brandColor,
        ),
      ),
    );
  }
}

/// Полноэкранный брендовый экран загрузки в стиле Ketroy
/// Соответствует дизайну ErrorScreen с градиентным фоном
class BrandedLoadingScreen extends StatefulWidget {
  final String? message;
  final bool showLogo;

  const BrandedLoadingScreen({
    super.key,
    this.message,
    this.showLogo = true,
  });

  @override
  State<BrandedLoadingScreen> createState() => _BrandedLoadingScreenState();
}

class _BrandedLoadingScreenState extends State<BrandedLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Логотип с пульсацией
              if (widget.showLogo) ...[
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: _buildLogo(),
                ),
                SizedBox(height: 40.h),
              ],
              
              // Кастомный спиннер
              _buildCustomSpinner(),
              
              // Текст загрузки
              if (widget.message != null) ...[
                SizedBox(height: 24.h),
                Text(
                  widget.message!,
                  style: AppTheme.textStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100.w,
      height: 100.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Center(
        child: Image.asset(
          'images/logoK.png',
          width: 60.w,
          height: 60.w,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.shopping_bag_outlined,
            size: 48.sp,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSpinner() {
    return SizedBox(
      width: 48.w,
      height: 48.w,
      child: CircularProgressIndicator(
        strokeWidth: 3.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white.withValues(alpha: 0.9),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.2),
      ),
    );
  }
}

/// Компактный виджет загрузки для встраивания внутри других экранов
/// Используется когда нужно показать загрузку без полноэкранного Scaffold
class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool isCompact;
  final Color? color;

  const LoadingWidget({
    super.key,
    this.message,
    this.isCompact = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 16.w : 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: isCompact ? 32.w : 44.w,
              height: isCompact ? 32.w : 44.w,
              child: CircularProgressIndicator(
                strokeWidth: isCompact ? 2.5 : 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? AppTheme.brandColor,
                ),
              ),
            ),
            if (message != null) ...[
              SizedBox(height: isCompact ? 12.h : 16.h),
              Text(
                message!,
                style: AppTheme.textStyle(
                  fontSize: isCompact ? 14.sp : 15.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Лоадер в стиле skeleton (shimmer эффект) для списков
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius.r),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
              ],
              colors: [
                const Color(0xFFE0E0E0),
                const Color(0xFFF5F5F5),
                const Color(0xFFE0E0E0),
              ],
            ),
          ),
        );
      },
    );
  }
}
