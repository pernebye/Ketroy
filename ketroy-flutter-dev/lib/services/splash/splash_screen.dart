import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/theme/theme.dart';

class KetroyStyleSplashScreen extends StatefulWidget {
  const KetroyStyleSplashScreen({super.key});

  @override
  State<KetroyStyleSplashScreen> createState() =>
      _KetroyStyleSplashScreenState();
}

class _KetroyStyleSplashScreenState extends State<KetroyStyleSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() async {
    // Start logo animation
    await _logoController.forward();

    // Start pulse animation (repeats)
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoController.dispose();
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
              const Spacer(flex: 2),
              
              // Логотип с анимацией
              AnimatedBuilder(
                animation: Listenable.merge([_logoController, _pulseController]),
                builder: (context, child) {
                  final pulseValue = _pulseController.isAnimating 
                      ? _pulseAnimation.value 
                      : 1.0;
                  return Opacity(
                    opacity: _logoOpacityAnimation.value,
                    child: Transform.scale(
                      scale: _logoScaleAnimation.value * pulseValue,
                      child: child,
                    ),
                  );
                },
                child: _buildLogoContainer(),
              ),
              
              SizedBox(height: 32.h),
              
              // Название бренда
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacityAnimation.value,
                    child: child,
                  );
                },
                child: Text(
                  'KETROY',
                  style: AppTheme.textStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 8,
                  ),
                ),
              ),
              
              const Spacer(flex: 1),
              
              // Индикатор загрузки
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacityAnimation.value,
                    child: child,
                  );
                },
                child: _buildLoadingIndicator(),
              ),
              
              const Spacer(flex: 1),
              
              // Bottom padding
              SizedBox(height: 48.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoContainer() {
    return Container(
      width: 140.w,
      height: 140.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 100.w,
          height: 100.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Image.asset(
              'images/logoK.png',
              width: 70.w,
              height: 70.w,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.shopping_bag_outlined,
                size: 56.sp,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40.w,
          height: 40.w,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.8),
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Загрузка...',
          style: AppTheme.textStyle(
            fontSize: 14.sp,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
