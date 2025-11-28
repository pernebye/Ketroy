import 'package:flutter/material.dart';

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
/// Позволяет закрыть экран свайпом вправо (как в iOS)
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

class _SwipeBackWrapperState extends State<SwipeBackWrapper> {
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      onHorizontalDragStart: (details) {
        // Начинаем только с левого края экрана (зона 40px)
        if (details.localPosition.dx < 40) {
          setState(() {
            _isDragging = true;
            _dragOffset = 0;
          });
        }
      },
      onHorizontalDragUpdate: (details) {
        if (_isDragging) {
          setState(() {
            _dragOffset = (details.primaryDelta ?? 0) + _dragOffset;
            _dragOffset =
                _dragOffset.clamp(0, MediaQuery.of(context).size.width);
          });
        }
      },
      onHorizontalDragEnd: (details) {
        if (_isDragging) {
          final velocity = details.primaryVelocity ?? 0;
          final screenWidth = MediaQuery.of(context).size.width;

          // Закрываем если свайпнули больше 30% или быстро
          if (_dragOffset > screenWidth * 0.3 || velocity > 500) {
            if (widget.onSwipeBack != null) {
              widget.onSwipeBack!();
            } else {
              Navigator.of(context).pop();
            }
          }

          setState(() {
            _isDragging = false;
            _dragOffset = 0;
          });
        }
      },
      onHorizontalDragCancel: () {
        setState(() {
          _isDragging = false;
          _dragOffset = 0;
        });
      },
      child: AnimatedContainer(
        duration:
            _isDragging ? Duration.zero : const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(_dragOffset, 0, 0),
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
