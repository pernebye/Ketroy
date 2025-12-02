import 'package:flutter/material.dart';

/// Простой Slide Route - страница выезжает справа налево (iOS-style)
/// Полностью закрывает предыдущий экран
class SlideRightRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideRightRoute({
    required this.page,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Кривая анимации - как в iOS
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            // Slide from right to left
            final slideAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0), // Начинаем справа за экраном
              end: Offset.zero,
            ).animate(curvedAnimation);

            return SlideTransition(
              position: slideAnimation,
              child: child,
            );
          },
        );

  @override
  bool get opaque => true;
  
  @override
  bool get maintainState => true;
}

/// Slide Over Page Route - эффект как в Instagram Direct
/// Новый экран выезжает справа поверх текущего контента
/// с лёгким затемнением фона и закруглёнными углами
class SlideOverPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final bool enableSwipeBack;
  final double borderRadius;

  SlideOverPageRoute({
    required this.page,
    this.enableSwipeBack = true,
    this.borderRadius = 16.0, // Закруглённые углы как в Instagram
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          opaque: false, // Важно! Позволяет видеть предыдущий экран
          barrierColor: Colors.transparent, // Убираем дефолтный barrier
          barrierDismissible: false,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Кривая анимации - как в iOS
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            // Slide from right
            final slideAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0), // Начинаем справа за экраном
              end: Offset.zero,
            ).animate(curvedAnimation);

            // Fade для затемнения фона
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curvedAnimation);

            // Анимация закругления углов (больше в начале, меньше в конце)
            final radiusAnimation = Tween<double>(
              begin: 24.0,
              end: 16.0,
            ).animate(curvedAnimation);

            return Stack(
              children: [
                // Затемнение фона (с возможностью закрыть по тапу)
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                // Новый экран с закруглёнными углами, выезжающий справа
                SlideTransition(
                  position: slideAnimation,
                  child: AnimatedBuilder(
                    animation: radiusAnimation,
                    builder: (context, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(radiusAnimation.value),
                          bottomLeft: Radius.circular(radiusAnimation.value),
                        ),
                        child: child,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );

  @override
  bool get maintainState => true;
}

/// Виджет-обёртка для добавления свайп-жеста закрытия
/// Позволяет закрыть экран свайпом вправо с любого места экрана
class SwipeBackWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeBack;
  final bool enabled;

  const SwipeBackWrapper({
    super.key,
    required this.child,
    this.onSwipeBack,
    this.enabled = true,
  });

  @override
  State<SwipeBackWrapper> createState() => _SwipeBackWrapperState();
}

class _SwipeBackWrapperState extends State<SwipeBackWrapper>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _isDragging = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _resetPosition() {
    _animation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = 0;
          _isDragging = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      // Разрешаем начинать свайп с любого места экрана
      onHorizontalDragStart: (details) {
        _animationController.stop();
        setState(() {
          _isDragging = true;
          _dragOffset = 0;
        });
      },
      onHorizontalDragUpdate: (details) {
        if (_isDragging) {
          final delta = details.primaryDelta ?? 0;
          setState(() {
            // Только свайп вправо (положительное значение)
            _dragOffset = (_dragOffset + delta).clamp(0.0, MediaQuery.of(context).size.width);
          });
        }
      },
      onHorizontalDragEnd: (details) {
        if (_isDragging) {
          final velocity = details.primaryVelocity ?? 0;
          final screenWidth = MediaQuery.of(context).size.width;

          // Закрываем если свайпнули больше 15% экрана или быстро вправо
          // Мягкий порог для удобства пользователя
          if (_dragOffset > screenWidth * 0.15 || velocity > 200) {
            if (widget.onSwipeBack != null) {
              widget.onSwipeBack!();
            } else {
              Navigator.of(context).pop();
            }
            setState(() {
              _isDragging = false;
              _dragOffset = 0;
            });
          } else {
            // Возвращаем экран на место с анимацией
            _resetPosition();
          }
        }
      },
      onHorizontalDragCancel: () {
        if (_isDragging) {
          _resetPosition();
        }
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final offset = _isDragging ? _dragOffset : _animation.value;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Утилита для навигации с Slide Over эффектом
class SlideOverNavigation {
  /// Открыть страницу с эффектом Slide Over (как Instagram Direct)
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(
      SlideOverPageRoute<T>(page: page),
    );
  }

  /// Открыть страницу и удалить предыдущую
  static Future<T?> pushReplacement<T, TO>(BuildContext context, Widget page) {
    return Navigator.of(context).pushReplacement<T, TO>(
      SlideOverPageRoute<T>(page: page),
    );
  }
}
