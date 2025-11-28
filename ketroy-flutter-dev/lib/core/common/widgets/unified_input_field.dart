import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Унифицированное поле ввода с фиксированной высотой
/// Используется для TextFormField, Container (дата), и обертки Dropdown
class UnifiedInputField extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const UnifiedInputField({
    super.key,
    required this.child,
    this.padding,
  });

  // Константы для единообразия всех полей
  static const double fieldHeight =
      56.0; // Фиксированная высота - оптимизированная для компактности
  static final EdgeInsetsGeometry defaultPadding = EdgeInsets.symmetric(
    horizontal: 20.w,
  );
  static final double borderRadius = 13.r;
  static const Color fillColor = Colors.white;
  static final TextStyle textStyle = TextStyle(
    fontSize: 17.sp,
    color: const Color(0xFF212121),
    fontWeight: FontWeight.w400,
    height: 1.0, // Точная высота строки для центрального выравнивания
  );
  static final TextStyle hintStyle = TextStyle(
    fontSize: 17.sp,
    color: const Color(0xFF212121).withValues(alpha: 0.5),
    fontWeight: FontWeight.w400,
    height: 1.0, // Точная высота строки для центрального выравнивания
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: fieldHeight.h,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: padding ?? defaultPadding,
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}
