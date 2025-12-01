import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/bonus/presentation/bloc/bonus_bloc.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart' show AppLiquidGlassSettings;
import 'package:ketroy_app/core/common/mixins/adaptive_header_mixin.dart';

class BonusPage extends StatefulWidget {
  const BonusPage({super.key});

  @override
  State<BonusPage> createState() => _BonusPageState();
}

class _BonusPageState extends State<BonusPage>
    with SingleTickerProviderStateMixin, AdaptiveHeaderMixin {
  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _darkBg = Color(0xFF1A1F12);
  static const Color _cardBg = Color(0xFFF5F7F0);

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    context.read<BonusBloc>().add(GetBonussesFetch());
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    
    // Инициализация адаптивного хедера
    initAdaptiveHeader(fallbackHeightRatio: 0.25);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _cardBg,
        body: BlocBuilder<BonusBloc, BonusState>(
          builder: (context, state) {
            if (!state.isSuccess) {
              return const Center(child: Loader());
            }
            return _buildContent(state);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BonusState state) {
    // Планируем измерение хедера
    scheduleHeaderMeasurement();
    
    return Stack(
      children: [
        // Адаптивный градиентный header
        buildAdaptiveGradient(colors: [_darkBg, _primaryGreen]),

        // Контент
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                KeyedSubtree(key: headerKey, child: _buildHeader()),
                SizedBox(height: 16.h),
                _buildBonusCard(state),
              ],
            ),
          ),
        ),
      ],
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
                  'Бонусная программа',
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
                    Icon(Icons.stars_rounded, size: 16.w, color: _accentGreen),
                    SizedBox(width: 6.w),
                    Text(
                      'Накапливайте и экономьте',
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

  Widget _buildBonusCard(BonusState state) {
    final bonus = state.bonuses.isNotEmpty ? state.bonuses[0] : null;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _animController.value)),
          child: Opacity(
            opacity: _animController.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение
            if (bonus?.image != null && bonus!.image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
                child: CachedNetworkImage(
                  imageUrl: bonus.image,
                  width: double.infinity,
                  height: 200.h,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200.h,
                    color: _cardBg,
                    child: const Center(child: CompactLoader()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200.h,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_lightGreen, _primaryGreen],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.stars_rounded,
                        size: 64.w,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 180.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_lightGreen, _primaryGreen],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.stars_rounded,
                    size: 64.w,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),

            // Контент
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Бейджик
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: _accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 14.w, color: _primaryGreen),
                        SizedBox(width: 6.w),
                        Text(
                          'НОВИНКИ',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: _primaryGreen,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Заголовок
                  Text(
                    bonus?.title ?? 'Бонусная программа',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Описание
                  Text(
                    bonus?.description ?? 'Накапливайте бонусы с каждой покупкой',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Инфо блоки
                  _buildInfoRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            icon: Icons.percent_rounded,
            title: 'До 10%',
            subtitle: 'Кэшбэк',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildInfoItem(
            icon: Icons.card_giftcard_rounded,
            title: 'Подарки',
            subtitle: 'За покупки',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildInfoItem(
            icon: Icons.star_rounded,
            title: 'VIP',
            subtitle: 'Статус',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: _primaryGreen, size: 24.w),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
