import 'package:flutter/material.dart';
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
