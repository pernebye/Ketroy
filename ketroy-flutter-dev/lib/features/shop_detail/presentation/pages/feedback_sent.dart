import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/widgets/auth_required_dialog.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/shop_detail/presentation/bloc/shop_detail_bloc.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:ketroy_app/services/shared_preferences_service.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart' show AppLiquidGlassSettings;

class FeedbackSent extends StatefulWidget {
  final int id;
  final String userId;

  const FeedbackSent({super.key, required this.id, required this.userId});

  @override
  State<FeedbackSent> createState() => _FeedbackSentState();
}

class _FeedbackSentState extends State<FeedbackSent>
    with SingleTickerProviderStateMixin {
  // Цвета
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _darkBg = Color(0xFF1A1F12);
  static const Color _cardBg = Color(0xFFF5F7F0);

  final TextEditingController reviewController = TextEditingController();
  int _rating = 0;
  final sharedService = serviceLocator<SharedPreferencesService>();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward();

    if (!sharedService.passed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFullScreenOverlay();
      });
    }
  }

  @override
  void dispose() {
    reviewController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _cardBg,
        body: BlocConsumer<ShopDetailBloc, ShopDetailState>(
          listener: (context, state) {
            if (state.isSendSuccess) {
              Navigator.pop(context);
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                // Градиент сверху
                Container(
                  height: 200.h,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_darkBg, _primaryGreen],
                    ),
                  ),
                ),

                // Контент
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(16.w),
                          child: _buildContent(state),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: LiquidGlass.withOwnLayer(
              settings: AppLiquidGlassSettings.button,
              shape: LiquidRoundedSuperellipse(borderRadius: 22.r),
              child: SizedBox(
                width: 44.w,
                height: 44.w,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Написать отзыв',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_rounded, size: 14.w, color: _accentGreen),
                    SizedBox(width: 6.w),
                    Text(
                      'Поделитесь впечатлениями',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 44.w),
        ],
      ),
    );
  }

  Widget _buildContent(ShopDetailState state) {
    return Column(
      children: [
        SizedBox(height: 16.h),

        // Карточка с рейтингом
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: _buildRatingCard(),
        ),

        SizedBox(height: 20.h),

        // Карточка с текстом отзыва
        _buildReviewCard(),

        SizedBox(height: 24.h),

        // Кнопка отправить
        _buildSubmitButton(state),
      ],
    );
  }

  Widget _buildRatingCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Иконка
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _accentGreen.withValues(alpha: 0.2),
                  _primaryGreen.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star_rounded,
              color: _primaryGreen,
              size: 32.w,
            ),
          ),

          SizedBox(height: 16.h),

          Text(
            'Оцените магазин',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 8.h),

          Text(
            _getRatingText(),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black45,
            ),
          ),

          SizedBox(height: 20.h),

          // Звезды
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isSelected = _rating >= starIndex;

              return GestureDetector(
                onTap: () => setState(() => _rating = starIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 44.w,
                    color: isSelected ? Colors.amber : Colors.grey.shade300,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'Очень плохо 😞';
      case 2:
        return 'Плохо 😕';
      case 3:
        return 'Нормально 😐';
      case 4:
        return 'Хорошо 😊';
      case 5:
        return 'Отлично! 🤩';
      default:
        return 'Нажмите на звезды для оценки';
    }
  }

  Widget _buildReviewCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review_rounded, color: _primaryGreen, size: 22.w),
              SizedBox(width: 10.w),
              Text(
                'Ваш отзыв',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: _focusNode.hasFocus
                    ? _primaryGreen
                    : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: reviewController,
              focusNode: _focusNode,
              maxLines: 5,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Расскажите о вашем опыте посещения магазина...',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black38,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16.w),
              ),
              onTap: () => setState(() {}),
              onEditingComplete: () {
                _focusNode.unfocus();
                setState(() {});
              },
            ),
          ),

          SizedBox(height: 12.h),

          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 14.w, color: Colors.black38),
              SizedBox(width: 6.w),
              Text(
                'Отзыв поможет другим покупателям',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ShopDetailState state) {
    final isEnabled = reviewController.text.isNotEmpty && _rating > 0;

    return GestureDetector(
      onTap: isEnabled && !state.isLoading
          ? () {
              context.read<ShopDetailBloc>().add(
                    SendShopReviewFetch(
                      shopId: widget.id.toString(),
                      userId: widget.userId,
                      review: reviewController.text,
                      rating: _rating.toString(),
                    ),
                  );
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_lightGreen, _primaryGreen],
                )
              : null,
          color: isEnabled ? null : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: state.isLoading
              ? const CompactLoader()
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.send_rounded,
                      color: isEnabled ? Colors.white : Colors.grey.shade500,
                      size: 20.w,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Отправить отзыв',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showFullScreenOverlay() {
    showGeneralDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AuthRequiredDialog(
          title: 'Требуется авторизация',
          message:
              'Чтобы оставить отзыв о магазине, необходимо войти в аккаунт!',
          isModal: true,
          onLoginPressed: () {
            Navigator.of(context).pop();
          },
          onCancel: () {
            Navigator.of(context).pop();
            NavScreen.globalKey.currentState?.setState(() {
              NavScreen.globalKey.currentState?.selectedTab = 0;
            });
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
    );
  }
}
