import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Виджет для создания экранов с адаптивным градиентным фоном.
/// 
/// Фон автоматически подстраивается под высоту хедера,
/// решая проблему несоответствия на разных устройствах.
class AdaptiveGradientScaffold extends StatefulWidget {
  /// Цвета градиента (сверху вниз)
  final List<Color> gradientColors;
  
  /// Виджет хедера (рендерится поверх градиента)
  final Widget header;
  
  /// Основной контент (рендерится под хедером с закруглением)
  final Widget content;
  
  /// Цвет фона контента
  final Color contentBackgroundColor;
  
  /// Радиус закругления контента
  final double? borderRadius;
  
  /// Дополнительный отступ между хедером и контентом
  /// Используется для создания "зоны перехода"
  final double extraHeaderPadding;
  
  /// Минимальная высота градиентной области
  /// Используется как fallback до измерения хедера
  final double? minGradientHeight;
  
  /// Callback при pull-to-refresh
  final Future<void> Function()? onRefresh;
  
  /// Цвет индикатора refresh
  final Color? refreshIndicatorColor;

  const AdaptiveGradientScaffold({
    super.key,
    required this.gradientColors,
    required this.header,
    required this.content,
    this.contentBackgroundColor = const Color(0xFFF5F7F0),
    this.borderRadius,
    this.extraHeaderPadding = 24,
    this.minGradientHeight,
    this.onRefresh,
    this.refreshIndicatorColor,
  });

  @override
  State<AdaptiveGradientScaffold> createState() => _AdaptiveGradientScaffoldState();
}

class _AdaptiveGradientScaffoldState extends State<AdaptiveGradientScaffold> {
  final GlobalKey _headerKey = GlobalKey();
  
  // Начальное значение с запасом для предотвращения мерцания
  double _gradientHeight = 0;
  bool _measured = false;

  @override
  void initState() {
    super.initState();
    // Измеряем после первого рендера
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  @override
  void didUpdateWidget(covariant AdaptiveGradientScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Перемеряем если контент изменился
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  void _measureHeader() {
    final context = _headerKey.currentContext;
    if (context != null) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final newHeight = renderBox.size.height + widget.extraHeaderPadding;
        // Обновляем только если есть значительное изменение
        if (!_measured || (_gradientHeight - newHeight).abs() > 5) {
          setState(() {
            _gradientHeight = newHeight;
            _measured = true;
          });
        }
      }
    }
  }

  double get _effectiveGradientHeight {
    if (_measured) {
      return _gradientHeight;
    }
    // Fallback: используем minGradientHeight или процент от экрана
    return widget.minGradientHeight ?? 
           MediaQuery.of(context).size.height * 0.4;
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? 32.r;
    
    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Хедер с измеряемым ключом
        SliverToBoxAdapter(
          child: KeyedSubtree(
            key: _headerKey,
            child: widget.header,
          ),
        ),
        
        // Контент с закруглением
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: widget.contentBackgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(radius),
                topRight: Radius.circular(radius),
              ),
            ),
            child: widget.content,
          ),
        ),
      ],
    );

    return Stack(
      children: [
        // Градиентный фон с адаптивной высотой
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: _effectiveGradientHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: widget.gradientColors,
            ),
          ),
        ),
        
        // Скроллируемый контент
        if (widget.onRefresh != null)
          RefreshIndicator(
            color: widget.refreshIndicatorColor ?? widget.gradientColors.last,
            onRefresh: widget.onRefresh!,
            child: scrollView,
          )
        else
          scrollView,
      ],
    );
  }
}


/// Миксин для использования в страницах с градиентным хедером.
/// Предоставляет стандартные цвета и утилиты.
mixin GradientPageMixin {
  // Стандартные цвета дизайна KETROY
  static const Color primaryGreen = Color(0xFF3C4B1B);
  static const Color lightGreen = Color(0xFF5A6F2B);
  static const Color accentGreen = Color(0xFF8BC34A);
  static const Color darkBg = Color(0xFF1A1F12);
  static const Color cardBg = Color(0xFFF5F7F0);
  
  /// Стандартные цвета градиента для профиля
  static List<Color> get profileGradientColors => [
    darkBg,
    primaryGreen,
    lightGreen.withValues(alpha: 0.8),
  ];
  
  /// Стандартные цвета градиента для внутренних страниц (настройки, подарки и т.д.)
  static List<Color> get pageGradientColors => [
    darkBg,
    primaryGreen,
  ];
}


/// Упрощенный виджет для страниц с простым хедером (как настройки, подарки)
class SimpleGradientPage extends StatelessWidget {
  final Widget header;
  final Widget content;
  final List<Color>? gradientColors;
  final Color? backgroundColor;
  final Future<void> Function()? onRefresh;
  
  const SimpleGradientPage({
    super.key,
    required this.header,
    required this.content,
    this.gradientColors,
    this.backgroundColor,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? GradientPageMixin.cardBg,
      body: AdaptiveGradientScaffold(
        gradientColors: gradientColors ?? GradientPageMixin.pageGradientColors,
        header: SafeArea(
          bottom: false,
          child: header,
        ),
        content: content,
        extraHeaderPadding: 16.h,
        onRefresh: onRefresh,
        refreshIndicatorColor: GradientPageMixin.accentGreen,
      ),
    );
  }
}


