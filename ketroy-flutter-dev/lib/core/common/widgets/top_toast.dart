import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Тип тоста
enum ToastType {
  success,
  error,
  warning,
  info,
}

/// Красивый тостер, появляющийся сверху экрана
class TopToast {
  static OverlayEntry? _currentOverlay;
  static Timer? _dismissTimer;

  // Цвета для разных типов
  static const Map<ToastType, Color> _backgroundColors = {
    ToastType.success: Color(0xFF3C4B1B),
    ToastType.error: Color(0xFFD32F2F),
    ToastType.warning: Color(0xFFF57C00),
    ToastType.info: Color(0xFF1976D2),
  };

  static const Map<ToastType, Color> _iconBackgroundColors = {
    ToastType.success: Color(0xFF8BC34A),
    ToastType.error: Color(0xFFEF5350),
    ToastType.warning: Color(0xFFFFB74D),
    ToastType.info: Color(0xFF64B5F6),
  };

  static const Map<ToastType, IconData> _icons = {
    ToastType.success: Icons.check_circle_rounded,
    ToastType.error: Icons.error_rounded,
    ToastType.warning: Icons.warning_rounded,
    ToastType.info: Icons.info_rounded,
  };

  /// Показать тост
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    OverlayState? overlayState,
  }) {
    try {
      // Убираем предыдущий тост если есть
      dismiss();

      // Безопасно получаем Overlay - сначала пробуем переданный, потом из контекста
      OverlayState? overlay = overlayState;
      overlay ??= Overlay.maybeOf(context);
      
      if (overlay == null) {
        debugPrint('⚠️ TopToast: No Overlay found, cannot show toast');
        return;
      }

      _currentOverlay = OverlayEntry(
        builder: (ctx) => _ToastWidget(
          message: message,
          title: title,
          type: type,
          onDismiss: dismiss,
          onTap: onTap,
        ),
      );

      overlay.insert(_currentOverlay!);

      // Автоматическое закрытие
      _dismissTimer = Timer(duration, dismiss);
    } catch (e) {
      debugPrint('⚠️ TopToast error: $e');
    }
  }

  /// Показать успешный тост
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    OverlayState? overlayState,
  }) {
    show(context, message: message, title: title, type: ToastType.success, duration: duration, overlayState: overlayState);
  }

  /// Показать тост ошибки
  static void showError(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
    OverlayState? overlayState,
  }) {
    show(context, message: message, title: title, type: ToastType.error, duration: duration, overlayState: overlayState);
  }

  /// Показать предупреждающий тост
  static void showWarning(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    OverlayState? overlayState,
  }) {
    show(context, message: message, title: title, type: ToastType.warning, duration: duration, overlayState: overlayState);
  }

  /// Показать информационный тост
  static void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    OverlayState? overlayState,
  }) {
    show(context, message: message, title: title, type: ToastType.info, duration: duration, overlayState: overlayState);
  }

  /// Закрыть тост
  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final String? title;
  final ToastType type;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const _ToastWidget({
    required this.message,
    this.title,
    required this.type,
    required this.onDismiss,
    this.onTap,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = TopToast._backgroundColors[widget.type]!;
    final iconBgColor = TopToast._iconBackgroundColors[widget.type]!;
    final icon = TopToast._icons[widget.type]!;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: () {
                widget.onTap?.call();
                _dismiss();
              },
              onVerticalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dy < -100) {
                  _dismiss();
                }
              },
              child: Container(
                margin: EdgeInsets.only(
                  top: topPadding + 8.h,
                  left: 16.w,
                  right: 16.w,
                ),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: backgroundColor.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              child: Row(
                children: [
                  // Иконка
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: iconBgColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24.w,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  // Текст
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.title != null) ...[
                          Text(
                            widget.title!,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                        ],
                        Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Кнопка закрытия
                  GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 16.w,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

