import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Миксин для создания адаптивных градиентных хедеров.
/// 
/// Автоматически измеряет высоту хедера и подстраивает высоту градиента.
/// Решает проблему несоответствия градиента контенту на разных устройствах.
/// 
/// Использование:
/// ```dart
/// class _MyPageState extends State<MyPage> with AdaptiveHeaderMixin {
///   @override
///   void initState() {
///     super.initState();
///     initAdaptiveHeader(); // Инициализация
///   }
///   
///   @override
///   Widget build(BuildContext context) {
///     scheduleHeaderMeasurement(); // Вызывать в build
///     
///     return Stack(
///       children: [
///         buildAdaptiveGradient(colors: [...]),
///         // header с headerKey
///         KeyedSubtree(key: headerKey, child: yourHeader),
///       ],
///     );
///   }
/// }
/// ```
mixin AdaptiveHeaderMixin<T extends StatefulWidget> on State<T> {
  /// Ключ для измерения хедера
  final GlobalKey headerKey = GlobalKey();
  
  /// Текущая измеренная высота градиента
  double gradientHeight = 0;
  
  /// Флаг успешного измерения
  bool headerMeasured = false;
  
  /// Дополнительный отступ для плавного перехода к контенту
  double extraPadding = 32;
  
  /// Коэффициент для fallback высоты (процент от высоты экрана)
  double fallbackHeightRatio = 0.22;
  
  /// Минимальная высота градиента (гарантирует достаточно места для хедера)
  double minGradientHeight = 120;

  /// Инициализация адаптивного хедера.
  /// Вызывать в initState после super.initState()
  void initAdaptiveHeader({
    double extraPadding = 32,
    double fallbackHeightRatio = 0.22,
    double minGradientHeight = 120,
  }) {
    this.extraPadding = extraPadding;
    this.fallbackHeightRatio = fallbackHeightRatio;
    this.minGradientHeight = minGradientHeight;
    WidgetsBinding.instance.addPostFrameCallback((_) => measureHeaderHeight());
  }

  /// Измеряет высоту хедера и обновляет градиент.
  /// Вызывается автоматически после initState и при scheduleHeaderMeasurement
  void measureHeaderHeight() {
    final context = headerKey.currentContext;
    if (context != null) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final newHeight = renderBox.size.height + extraPadding.h;
        if (!headerMeasured || (gradientHeight - newHeight).abs() > 5) {
          setState(() {
            gradientHeight = newHeight;
            headerMeasured = true;
          });
        }
      }
    }
  }

  /// Планирует измерение после текущего билда.
  /// Вызывать в начале build метода.
  void scheduleHeaderMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) => measureHeaderHeight());
  }

  /// Возвращает эффективную высоту градиента.
  /// Использует измеренную высоту или fallback, с гарантией минимальной высоты.
  double getEffectiveGradientHeight(BuildContext context) {
    final minHeight = minGradientHeight.h;
    if (headerMeasured) {
      return gradientHeight.clamp(minHeight, double.infinity);
    }
    final fallbackHeight = MediaQuery.of(context).size.height * fallbackHeightRatio;
    return fallbackHeight.clamp(minHeight, double.infinity);
  }

  /// Создает AnimatedContainer с градиентом.
  /// 
  /// [colors] - цвета градиента сверху вниз
  /// [duration] - длительность анимации изменения высоты
  Widget buildAdaptiveGradient({
    required List<Color> colors,
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.easeOut,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      height: getEffectiveGradientHeight(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
    );
  }
}


/// Стандартные цвета дизайна KETROY для градиентов
class KetroyColors {
  KetroyColors._();
  
  static const Color primaryGreen = Color(0xFF3C4B1B);
  static const Color lightGreen = Color(0xFF5A6F2B);
  static const Color accentGreen = Color(0xFF8BC34A);
  static const Color darkBg = Color(0xFF1A1F12);
  static const Color cardBg = Color(0xFFF5F7F0);
  
  /// Цвета градиента для страницы профиля
  static List<Color> get profileGradient => [
    darkBg,
    primaryGreen,
    lightGreen.withValues(alpha: 0.8),
  ];
  
  /// Цвета градиента для внутренних страниц
  static List<Color> get pageGradient => [
    darkBg,
    primaryGreen,
  ];
}

