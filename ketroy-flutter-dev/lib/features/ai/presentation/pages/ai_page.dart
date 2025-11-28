import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/widgets/auth_required_dialog.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/ai/presentation/bloc/ai_bloc.dart';
import 'package:ketroy_app/features/ai/presentation/pages/label_scanner_sheet.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late AnimationController _messageController;
  late List<Animation<double>> _messageAnimations;
  final ScrollController _scrollController = ScrollController();

  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _darkBg = Color(0xFF1A1F12);
  static const Color _cardBg = Color(0xFFF5F7F0);

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Анимации для сообщений
    _messageAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _messageController,
          curve: Interval(
            index * 0.2,
            0.4 + index * 0.2,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _messageController.forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String cleanAnalysisText(String text) {
    return text
        .replaceAll('\\n', '\n')
        .replaceAll('\\t', '    ')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('###', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Widget _buildLoginDialog(BuildContext context, AppLocalizations l10n) {
    return AuthRequiredDialog(
      title: l10n.authRequired,
      message: l10n.aiAuthRequired,
      onCancel: () {
        // Переходим на главную вкладку при нажатии "Отмена"
        NavScreen.globalKey.currentState?.switchToTab(0);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _cardBg,
        // ValueListenableBuilder слушает изменения состояния авторизации
        // и пересоздаёт FutureBuilder при каждом login/logout
        body: ValueListenableBuilder<int>(
          valueListenable: UserDataManager.authStateNotifier,
          builder: (context, authVersion, _) {
            return FutureBuilder<bool>(
              // Уникальный ключ заставляет FutureBuilder пересоздаваться
              // при изменении authVersion
              key: ValueKey('auth_check_$authVersion'),
              future: UserDataManager.isUserLoggedIn(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Loader();
                }

                final isLoggedIn = snapshot.data ?? false;

                if (!isLoggedIn) {
                  return _buildLoginDialog(context, l10n);
                }

                return BlocConsumer<AiBloc, AiState>(
              listener: (context, state) {
                if (state.isFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message ?? l10n.errorOccurred),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
                if (state.analyzeResult != null) {
                  // Прокрутка к новому сообщению
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                }
              },
              builder: (context, state) {
                return Stack(
                  children: [
                    // Фоновый градиент
                    _buildBackground(),

                    // Основной контент
                    SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          // Кастомный Header
                          _buildHeader(l10n),

                          // Чат область
                          Expanded(
                            child: _buildChatArea(state, l10n),
                          ),

                          // Нижняя панель с кнопкой
                          _buildBottomPanel(state, l10n),
                        ],
                      ),
                    ),
                  ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _darkBg,
            _primaryGreen.withValues(alpha: 0.3),
            _cardBg,
          ],
          stops: const [0.0, 0.25, 0.45],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
      child: Column(
        children: [
          Row(
            children: [
              // AI Аватар с пульсацией
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.08);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _accentGreen,
                            _lightGreen,
                            _primaryGreen,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _accentGreen.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: 16.w),

              // Текст
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KETROY AI',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _accentGreen,
                            boxShadow: [
                              BoxShadow(
                                color: _accentGreen.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          l10n.virtualAssistant,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white70,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Волнистая линия-разделитель
          SizedBox(height: 20.h),
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(double.infinity, 20.h),
                painter: WavePainter(
                  animation: _waveController.value,
                  color: _accentGreen.withValues(alpha: 0.3),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(AiState state, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
          children: [
            // Приветственные сообщения
            _buildAnimatedMessage(
              index: 0,
              child: _buildAiMessage(
                l10n.aiGreeting,
                isFirst: true,
              ),
            ),
            SizedBox(height: 12.h),
            _buildAnimatedMessage(
              index: 1,
              child: _buildAiMessage(
                l10n.aiInstructions,
              ),
            ),

            // Результат анализа
            if (state.analyzeResult != null) ...[
              SizedBox(height: 16.h),
              _buildAnalysisResult(
                  cleanAnalysisText(state.analyzeResult!.analysis), l10n),
            ],

            // Индикатор загрузки
            if (state.isLoading) ...[
              SizedBox(height: 16.h),
              _buildLoadingMessage(l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedMessage(
      {required int index, required Widget child}) {
    if (index >= _messageAnimations.length) {
      return child;
    }
    return AnimatedBuilder(
      animation: _messageAnimations[index],
      builder: (context, _) {
        final value = _messageAnimations[index].value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildAiMessage(String text, {bool isFirst = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Аватар AI
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _lightGreen,
                _primaryGreen,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'AI',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),

        // Bubble сообщения
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4.r),
                topRight: Radius.circular(20.r),
                bottomLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.black87,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        SizedBox(width: 40.w), // Отступ справа для баланса
      ],
    );
  }

  Widget _buildAnalysisResult(String text, AppLocalizations l10n) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Аватар AI с особым оформлением для результата
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _accentGreen,
                  _lightGreen,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _accentGreen.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 22.w,
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Карточка результата
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    _cardBg,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4.r),
                  topRight: Radius.circular(20.r),
                  bottomLeft: Radius.circular(20.r),
                  bottomRight: Radius.circular(20.r),
                ),
                border: Border.all(
                  color: _accentGreen.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        color: _accentGreen,
                        size: 18.w,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        l10n.analysisResult,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: _primaryGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.black87,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 24.w),
        ],
      ),
    );
  }

  Widget _buildLoadingMessage(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Аватар AI
        Container(
          width: 40.w,
          height: 40.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _lightGreen,
                _primaryGreen,
              ],
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 20.w,
              height: 20.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),

        // Typing indicator
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4.r),
              topRight: Radius.circular(20.r),
              bottomLeft: Radius.circular(20.r),
              bottomRight: Radius.circular(20.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTypingDot(0),
              SizedBox(width: 4.w),
              _buildTypingDot(1),
              SizedBox(width: 4.w),
              _buildTypingDot(2),
              SizedBox(width: 12.w),
              Text(
                l10n.analyzing,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final delay = index * 0.2;
            final animValue = ((_pulseController.value + delay) % 1.0);
            final scale = 0.6 + (math.sin(animValue * math.pi) * 0.4);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryGreen.withValues(alpha: 0.6 + (scale - 0.6)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomPanel(AiState state, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Подсказка
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: _primaryGreen,
                    size: 20.w,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      l10n.pointCameraAtLabel,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.black54,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Кнопка сканирования
            GestureDetector(
              onTap: state.isLoading
                  ? null
                  : () {
                      showLabelScannerSheet(context);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 18.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: state.isLoading
                        ? [Colors.grey.shade400, Colors.grey.shade500]
                        : [_lightGreen, _primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: state.isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: _primaryGreen.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 24.w,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      state.isLoading ? l10n.processing : l10n.scanLabel,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Отступ для NavBar
            SizedBox(height: NavBar.getBottomPadding(context)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WAVE PAINTER - Рисует анимированную волну
// ============================================================================

class WavePainter extends CustomPainter {
  final double animation;
  final Color color;

  WavePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final waveHeight = size.height * 0.4;
    final waveLength = size.width / 2;

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 +
          math.sin((x / waveLength * 2 * math.pi) + (animation * 2 * math.pi)) *
              waveHeight;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Вторая волна с меньшей амплитудой
    final paint2 = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path2 = Path();
    path2.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 +
          math.sin((x / waveLength * 2 * math.pi) -
                  (animation * 2 * math.pi) +
                  0.5) *
              (waveHeight * 0.6);
      path2.lineTo(x, y);
    }

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
