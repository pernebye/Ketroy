import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/features/my_gifts/data/data_source/gift_data_source.dart';

/// Страница выбора подарка из группы
/// Показывает от 1 до 4 подарков, пользователь нажимает на один,
/// и ему рандомно выпадает один из них
class GiftSelectionPage extends StatefulWidget {
  final String giftGroupId;
  final List<GiftOption> gifts;

  const GiftSelectionPage({
    super.key,
    required this.giftGroupId,
    required this.gifts,
  });

  @override
  State<GiftSelectionPage> createState() => _GiftSelectionPageState();
}

class _GiftSelectionPageState extends State<GiftSelectionPage>
    with TickerProviderStateMixin {
  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _darkBg = Color(0xFF1A1F12);
  static const Color _cardBg = Color(0xFFF5F7F0);

  bool _isSelecting = false;
  bool _isRevealed = false;
  GiftOption? _selectedGift;
  int? _revealingIndex;
  
  late AnimationController _pulseController;
  late AnimationController _revealController;
  late Animation<double> _scaleAnimation;

  final GiftDataSourceImpl _giftDataSource = GiftDataSourceImpl();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _onGiftTap(int index) async {
    if (_isSelecting || _isRevealed) return;

    HapticFeedback.mediumImpact();
    
    setState(() {
      _isSelecting = true;
      _revealingIndex = index;
    });

    try {
      // Запрос к серверу для рандомного выбора
      final result = await _giftDataSource.selectGift(
        giftGroupId: widget.giftGroupId,
      );

      if (result.gift != null) {
        // Анимация "перемешивания" - мигаем разными подарками
        for (int i = 0; i < 8; i++) {
          if (!mounted) return;
          await Future.delayed(const Duration(milliseconds: 100));
          setState(() {
            _revealingIndex = Random().nextInt(widget.gifts.length);
          });
          HapticFeedback.selectionClick();
        }

        // Показываем результат
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (!mounted) return;
        setState(() {
          _selectedGift = result.gift;
          _isRevealed = true;
          // Находим индекс выбранного подарка для анимации
          _revealingIndex = widget.gifts.indexWhere((g) => g.id == result.gift!.id);
          if (_revealingIndex == -1) _revealingIndex = 0;
        });

        HapticFeedback.heavyImpact();
        _revealController.forward();

        // Показываем диалог с результатом
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _showResultDialog(result.gift!);
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Ошибка при выборе подарка');
        setState(() {
          _isSelecting = false;
          _revealingIndex = null;
        });
      }
    }
  }

  void _showResultDialog(GiftOption gift) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Анимированная иконка подарка
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 90.w,
                      height: 90.w,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_accentGreen, _primaryGreen],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _accentGreen.withValues(alpha: 0.5),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'images/giftR.png',
                        fit: BoxFit.contain,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20.h),
              
              // Изображение подарка
              if (gift.image != null)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: Image.network(
                      gift.image!,
                      width: 140.w,
                      height: 140.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 140.w,
                        height: 140.w,
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Image.asset(
                          'images/giftR.png',
                          width: 60.w,
                          height: 60.w,
                          color: _primaryGreen.withValues(alpha: 0.5),
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 20.h),
              
              // Конфетти эмодзи с анимацией
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.bounceOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Text(
                      '🎉 Поздравляем! 🎉',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: _primaryGreen,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 8.h),
              Text(
                'Вы получили:',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  gift.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              
              // Кнопка
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(true);
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_lightGreen, _primaryGreen],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Отлично!',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _darkBg,
        body: Stack(
          children: [
            // Градиентный фон
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_darkBg, _primaryGreen],
                ),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  // Заголовок
                  _buildHeader(),
                  
                  SizedBox(height: 32.h),
                  
                  // Подсказка
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Text(
                      _isRevealed
                          ? 'Ваш подарок:'
                          : 'Нажмите на любой подарок,\nчтобы узнать что внутри!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 40.h),
                  
                  // Сетка подарков
                  Expanded(
                    child: Center(
                      child: _buildGiftGrid(),
                    ),
                  ),
                  
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 22.w,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Выберите подарок',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 44.w),
        ],
      ),
    );
  }

  Widget _buildGiftGrid() {
    final count = widget.gifts.length;
    
    // Определяем раскладку в зависимости от количества подарков
    if (count == 1) {
      // 1 подарок - по центру
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Center(
          child: SizedBox(
            width: 120.w,
            height: 120.w,
            child: _buildGiftItem(0),
          ),
        ),
      );
    } else if (count == 2) {
      // 2 подарка - рядом
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20.h,
            crossAxisSpacing: 20.w,
            childAspectRatio: 1.0,
          ),
          itemCount: count,
          itemBuilder: (context, index) {
            return _buildGiftItem(index);
          },
        ),
      );
    } else if (count == 3) {
      // 3 подарка - пирамида (1 сверху, 2 внизу)
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Первый подарок - сверху по центру
            Center(
              child: SizedBox(
                width: 120.w,
                height: 120.w,
                child: _buildGiftItem(0),
              ),
            ),
            SizedBox(height: 20.h),
            // Два подарка внизу
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120.w,
                  height: 120.w,
                  child: _buildGiftItem(1),
                ),
                SizedBox(width: 20.w),
                SizedBox(
                  width: 120.w,
                  height: 120.w,
                  child: _buildGiftItem(2),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // 4+ подарка - сетка 2x2 (или больше)
      const crossAxisCount = 2;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 20.h,
            crossAxisSpacing: 20.w,
            childAspectRatio: 1.0,
          ),
          itemCount: count,
          itemBuilder: (context, index) {
            return _buildGiftItem(index);
          },
        ),
      );
    }
  }

  Widget _buildGiftItem(int index) {
    final gift = widget.gifts[index];
    final isHighlighted = _revealingIndex == index;
    final isWinner = _isRevealed && _selectedGift?.id == gift.id;
    final isNotWinner = _isRevealed && !isWinner;

    return GestureDetector(
      onTap: () => _onGiftTap(index),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          double scale = 1.0;
          double glowIntensity = 0.0;
          
          if (!_isRevealed && !_isSelecting) {
            // Пульсация для привлечения внимания
            scale = 1.0 + (_pulseController.value * 0.02);
            glowIntensity = _pulseController.value * 0.3;
          }
          if (isHighlighted && !_isRevealed) {
            scale = 1.05;
            glowIntensity = 0.6;
          }
          if (isWinner) {
            scale = _scaleAnimation.value;
            glowIntensity = 0.8;
          }
          if (isNotWinner) {
            scale = 0.9;
          }

          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                // Белая карточка с мягким градиентом
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isWinner
                      ? [Colors.white, const Color(0xFFF0F7E6)]
                      : isNotWinner
                          ? [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.3)]
                          : [Colors.white, Colors.white.withValues(alpha: 0.95)],
                ),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: isHighlighted || isWinner
                      ? _accentGreen
                      : Colors.white.withValues(alpha: 0.5),
                  width: isHighlighted || isWinner ? 3 : 2,
                ),
                boxShadow: [
                  // Основная тень
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isNotWinner ? 0.05 : 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  // Glow эффект
                  if (glowIntensity > 0)
                    BoxShadow(
                      color: _accentGreen.withValues(alpha: glowIntensity),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  // Внутреннее свечение сверху (эффект глубины)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Блик сверху слева для объёма
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    right: 40.w,
                    child: Container(
                      height: 20.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.6),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Контент
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Иконка подарка или результат
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: (!_isRevealed || !isWinner)
                              ? _buildGiftIcon(isHighlighted, isNotWinner)
                              : _buildWinnerContent(gift),
                        ),
                        SizedBox(height: 12.h),
                        // Текст "Нажми" или результат
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: _isRevealed && isWinner ? 13.sp : 12.sp,
                            fontWeight: FontWeight.w600,
                            color: isNotWinner
                                ? _primaryGreen.withValues(alpha: 0.4)
                                : _primaryGreen,
                          ),
                          child: Text(
                            _isRevealed
                                ? (isWinner ? gift.name : '—')
                                : 'Нажми!',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Галочка для выигранного
                  if (isWinner)
                    Positioned(
                      top: 10.h,
                      right: 10.w,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_accentGreen, _primaryGreen],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _accentGreen.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20.w,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Иконка подарка (до раскрытия)
  Widget _buildGiftIcon(bool isHighlighted, bool isNotWinner) {
    return Container(
      key: const ValueKey('gift_icon'),
      width: 80.w,
      height: 80.w,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isNotWinner
            ? _primaryGreen.withValues(alpha: 0.05)
            : _primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isHighlighted
              ? _accentGreen.withValues(alpha: 0.5)
              : _primaryGreen.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Image.asset(
        'images/giftR.png',
        fit: BoxFit.contain,
        color: isNotWinner ? _primaryGreen.withValues(alpha: 0.3) : null,
        colorBlendMode: isNotWinner ? BlendMode.srcIn : null,
      ),
    );
  }

  /// Контент для выигравшего подарка
  Widget _buildWinnerContent(GiftOption gift) {
    return ClipRRect(
      key: const ValueKey('winner_content'),
      borderRadius: BorderRadius.circular(16.r),
      child: gift.image != null
          ? Image.network(
              gift.image!,
              width: 80.w,
              height: 80.w,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16.r),
      ),
      padding: EdgeInsets.all(16.w),
      child: Image.asset(
        'images/giftR.png',
        fit: BoxFit.contain,
        color: _primaryGreen.withValues(alpha: 0.4),
        colorBlendMode: BlendMode.srcIn,
      ),
    );
  }
}


