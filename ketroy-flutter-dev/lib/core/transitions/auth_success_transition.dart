import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Overlay виджет для анимации приветствия после авторизации/регистрации
/// Показывается ПОВЕРХ витрины (NavScreen)
/// 
/// Эффекты:
/// 1. Размытие всего экрана
/// 2. Появление логотипа KETROY с эффектом свечения
/// 3. Пульсация и масштабирование логотипа
/// 4. Плавное снятие размытия
class WelcomeAnimationOverlay extends StatefulWidget {
  /// Callback после завершения анимации
  final VoidCallback onComplete;
  
  /// Длительность всей анимации в миллисекундах
  final int durationMs;

  const WelcomeAnimationOverlay({
    super.key,
    required this.onComplete,
    this.durationMs = 2800, // 2.8 секунды - достаточно чтобы увидеть
  });

  @override
  State<WelcomeAnimationOverlay> createState() => _WelcomeAnimationOverlayState();
}

class _WelcomeAnimationOverlayState extends State<WelcomeAnimationOverlay>
    with TickerProviderStateMixin {
  
  // Контроллер основной анимации
  late AnimationController _mainController;
  
  // Контроллер для пульсации
  late AnimationController _pulseController;
  
  // Анимации
  late Animation<double> _blurAnimation;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeOutAnimation;
  late Animation<double> _pulseAnimation;

  // Брендовый цвет KETROY
  static const Color brandColor = Color(0xFF3C4B1B);
  static const Color glowColor = Color(0xFF5A6F2B);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimation();
  }

  void _initAnimations() {
    // Основной контроллер
    _mainController = AnimationController(
      duration: Duration(milliseconds: widget.durationMs),
      vsync: this,
    );

    // Пульсация логотипа
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // Размытие: быстро появляется, потом плавно уходит
    _blurAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 12, // 12% времени на появление размытия
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 18, end: 18),
        weight: 58, // 58% времени держим размытие (дольше!)
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 18, end: 0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30, // 30% времени на снятие размытия
      ),
    ]).animate(_mainController);

    // Прозрачность логотипа
    _logoOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 1),
        weight: 60, // Дольше держим логотип видимым
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 28,
      ),
    ]).animate(_mainController);

    // Масштаб логотипа - эффект "появления из центра"
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.4, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 47, // Дольше держим нормальный размер
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_mainController);

    // Свечение
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 25, end: 18),
        weight: 52, // Дольше держим свечение
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 18, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_mainController);

    // Затемнение фона
    _fadeOutAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0.6)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 0.6),
        weight: 58, // Дольше держим затемнение
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_mainController);

    // Пульсация
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimation() async {
    // Запускаем основную анимацию
    _mainController.forward();
    
    // Запускаем пульсацию с задержкой
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _pulseController.repeat(reverse: true);
    }

    // Ждем завершения анимации
    await Future.delayed(Duration(milliseconds: widget.durationMs));
    
    if (mounted) {
      _pulseController.stop();
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Material нужен чтобы убрать жёлтые линии под текстом
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _pulseController]),
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Размытие фона - показываем витрину сквозь размытие
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value,
                    sigmaY: _blurAnimation.value,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: _fadeOutAnimation.value * 0.4),
                  ),
                ),
              ),
              
              // Градиентный overlay для атмосферы
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          glowColor.withValues(alpha: _fadeOutAnimation.value * 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Логотип KETROY с эффектами
              Center(
                child: Transform.scale(
                  scale: _logoScale.value * _pulseAnimation.value,
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: _buildLogo(),
                  ),
                ),
              ),
              
              // Приветственный текст
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.32,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _logoOpacity.value,
                  child: _buildWelcomeText(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          // Основное свечение
          BoxShadow(
            color: glowColor.withValues(alpha: 0.55),
            blurRadius: _glowAnimation.value,
            spreadRadius: _glowAnimation.value * 0.25,
          ),
          // Внутреннее свечение
          BoxShadow(
            color: brandColor.withValues(alpha: 0.35),
            blurRadius: _glowAnimation.value * 0.4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(22.w),
        decoration: BoxDecoration(
          color: brandColor, // Брендовый цвет фона, чтобы белый логотип был виден
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 2,
          ),
        ),
        // Используем FadeInImage для плавной загрузки или fallback
        child: _buildLogoImage(),
      ),
    );
  }

  Widget _buildLogoImage() {
    return Image.asset(
      'images/logoK.png',
      width: 72.w,
      height: 72.w,
      fit: BoxFit.contain,
      // Кеширование изображения
      cacheWidth: 200,
      cacheHeight: 200,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Logo load error: $error');
        // Fallback - буква K
        return _buildTextLogo();
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        // Если изображение ещё загружается - показываем fallback
        return frame != null ? child : _buildTextLogo();
      },
    );
  }

  Widget _buildTextLogo() {
    return SizedBox(
      width: 72.w,
      height: 72.w,
      child: Center(
        child: Text(
          'K',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 56.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white, // Белый текст на тёмном фоне
            letterSpacing: 2,
            decoration: TextDecoration.none, // Убираем подчёркивание
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // KETROY текст
        Text(
          'KETROY',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 28.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 6,
            decoration: TextDecoration.none, // Убираем подчёркивание
            shadows: [
              Shadow(
                color: brandColor.withValues(alpha: 0.45),
                blurRadius: 16,
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        // Подзаголовок
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            'Добро пожаловать в клуб привилегий',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.92),
              letterSpacing: 0.8,
              decoration: TextDecoration.none, // Убираем подчёркивание
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
