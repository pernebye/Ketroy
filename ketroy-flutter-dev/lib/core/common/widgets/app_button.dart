import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.width,
    this.height,
    this.borderColor,
    this.textColor,
    this.backgroundColor,
    this.enabled = true,
    this.icon,
    this.needBold = false,
  });
  final String title;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final Color? borderColor;
  final Color? textColor;
  final Color? backgroundColor;
  final bool enabled;
  final IconData? icon;
  final bool needBold;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && widget.onPressed != null) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();

      if (widget.enabled && widget.onPressed != null) {
        widget.onPressed!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              width: widget.width,
              height: widget.height,
              padding:
                  EdgeInsets.symmetric(vertical: 19.5.h, horizontal: 36.5.w),
              decoration: BoxDecoration(
                  color: widget.backgroundColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(13.r),
                  border: widget.borderColor != null
                      ? Border.all(color: widget.borderColor!)
                      : null),
              child: _buildContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    final textColor = widget.backgroundColor == Colors.white
        ? Colors.black
        : widget.textColor ?? Colors.white;

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.icon,
            color: textColor,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            widget.title,
            style: TextStyle(
              color: textColor,
              fontSize: 15.sp,
              fontWeight: widget.needBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.title,
      style: TextStyle(
        color: textColor,
        fontSize: 15.sp,
        fontWeight: widget.needBold ? FontWeight.w700 : FontWeight.w400,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ============================================================================
// LIQUID GLASS BUTTON (Apple Style)
// Использует библиотеку liquid_glass_renderer для аутентичного эффекта
// ============================================================================

/// Стандартные настройки для LiquidGlass эффектов в приложении
/// Используется везде для консистентного Apple-like вида
class AppLiquidGlassSettings {
  static const LiquidGlassSettings standard = LiquidGlassSettings(
    thickness: 12,
    blur: 8,
    glassColor: Color(0x28FFFFFF),
    lightIntensity: 1.2,
    saturation: 1.15,
  );
  
  static const LiquidGlassSettings button = LiquidGlassSettings(
    thickness: 10,
    blur: 6,
    glassColor: Color(0x22FFFFFF),
    lightIntensity: 1.0,
    saturation: 1.1,
  );
  
  static const LiquidGlassSettings navBar = LiquidGlassSettings(
    thickness: 10,
    blur: 5,
    glassColor: Color.fromARGB(17, 226, 226, 226),
    lightIntensity: 1.3,
    saturation: 1.1,
  );
}

class GlassMorphism extends StatefulWidget {
  const GlassMorphism({
    super.key,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    this.margin = const EdgeInsets.all(0.0),
    this.height,
    this.width,
    required this.child,
    this.onPressed,
  });

  final double borderRadius;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Widget child;
  final double? width;
  final double? height;
  final VoidCallback? onPressed;

  @override
  State<GlassMorphism> createState() => _GlassMorphismState();
}

class _GlassMorphismState extends State<GlassMorphism>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // ✅ iOS: Быстрая анимация для мгновенного отклика
      duration: const Duration(milliseconds: 50),
      reverseDuration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.65).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !_isPressed) {
      _isPressed = true;
      _controller.forward();
      // ✅ iOS: Haptic feedback для мгновенного тактильного отклика
      if (Platform.isIOS) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && _isPressed) {
      _isPressed = false;
      _controller.reverse();
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (_isPressed) {
      _isPressed = false;
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // ✅ Ловит тапы по всей области
      // ✅ iOS: excludeFromSemantics для избежания конфликтов с accessibility
      excludeFromSemantics: true,
      onTapDown: widget.onPressed != null ? _onTapDown : null,
      onTapUp: widget.onPressed != null ? _onTapUp : null,
      onTapCancel: widget.onPressed != null ? _onTapCancel : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                margin: widget.margin,
                width: widget.width,
                constraints: BoxConstraints(
                  minHeight: widget.height ?? 53.h,
                ),
                child: LiquidGlass.withOwnLayer(
                  settings: AppLiquidGlassSettings.button,
                  shape: LiquidRoundedSuperellipse(borderRadius: widget.borderRadius.r),
                  child: Padding(
                    padding: widget.padding,
                    child: Center(child: widget.child),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// LIQUID GLASS BUTTON - Универсальная интерактивная кнопка
// С правильным hit testing и визуальным откликом
// ============================================================================

class LiquidGlassButton extends StatefulWidget {
  const LiquidGlassButton({
    super.key,
    required this.onTap,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 22.0,
    this.settings,
    this.enabled = true,
  });

  final VoidCallback onTap;
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final LiquidGlassSettings? settings;
  final bool enabled;

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // ✅ iOS: Мгновенный отклик при нажатии, плавный при отпускании
      duration: const Duration(milliseconds: 40),
      reverseDuration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.70).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled && !_isPressed) {
      _isPressed = true;
      _controller.forward();
      // ✅ iOS: Haptic feedback для идеального тактильного отклика
      if (Platform.isIOS) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enabled && _isPressed) {
      _isPressed = false;
      _controller.reverse();
      widget.onTap();
    }
  }

  void _onTapCancel() {
    if (_isPressed) {
      _isPressed = false;
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // ✅ Важно! Ловит тапы по всей области
      excludeFromSemantics: true, // ✅ iOS: Избегаем конфликтов с accessibility
      onTapDown: widget.enabled ? _onTapDown : null,
      onTapUp: widget.enabled ? _onTapUp : null,
      onTapCancel: widget.enabled ? _onTapCancel : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: widget.enabled ? _opacityAnimation.value : 0.5,
              child: LiquidGlass.withOwnLayer(
                settings: widget.settings ?? AppLiquidGlassSettings.button,
                shape: LiquidRoundedSuperellipse(borderRadius: widget.borderRadius.r),
                child: SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: Center(child: widget.child),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
