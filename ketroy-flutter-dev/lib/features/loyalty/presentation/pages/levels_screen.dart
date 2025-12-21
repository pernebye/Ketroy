import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/loyalty/domain/entities/loyalty_level_entity.dart';
import 'package:ketroy_app/features/loyalty/presentation/bloc/loyalty_bloc.dart';
import 'package:ketroy_app/init_dependencies.dart';

/// Экран со всеми уровнями лояльности
class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: serviceLocator<LoyaltyBloc>()..add(const LoadLoyaltyInfo()),
      child: const _LevelsScreenContent(),
    );
  }
}

class _LevelsScreenContent extends StatelessWidget {
  const _LevelsScreenContent();

  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _darkBg = Color(0xFF1A1F12);
  static const Color _cardBg = Color(0xFFF5F7F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cardBg,
      body: CustomScrollView(
        slivers: [
          // Градиентный AppBar
          SliverAppBar(
            expandedHeight: 180.h,
            pinned: true,
            backgroundColor: _darkBg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Уровни лояльности',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_darkBg, _primaryGreen, _lightGreen],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        size: 48.sp,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Совершайте покупки и получайте награды',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Контент
          BlocBuilder<LoyaltyBloc, LoyaltyState>(
            builder: (context, state) {
              if (state.status == LoyaltyStatus.loading) {
                return const SliverFillRemaining(
                  child: Center(child: Loader()),
                );
              }

              final loyaltyInfo = state.loyaltyInfo;
              if (loyaltyInfo == null) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48.sp,
                          color: Colors.black26,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Не удалось загрузить уровни',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: () {
                            context.read<LoyaltyBloc>().add(const LoadLoyaltyInfo());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryGreen,
                          ),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Прогресс-бар
                      _buildProgressSection(context, loyaltyInfo),
                      SizedBox(height: 24.h),

                      // Список уровней
                      Text(
                        'Все уровни',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      ...loyaltyInfo.allLevels.map((level) {
                        return _buildLevelCard(
                          context,
                          level,
                          isCurrentLevel: loyaltyInfo.currentLevel?.id == level.id,
                        );
                      }),
                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, dynamic loyaltyInfo) {
    final currentLevel = loyaltyInfo.currentLevel;
    final nextLevel = loyaltyInfo.nextLevel;
    final progress = loyaltyInfo.progressPercent / 100;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (currentLevel != null) ...[
                Text(
                  currentLevel.icon ?? '🏆',
                  style: TextStyle(fontSize: 28.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ваш уровень',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.black45,
                        ),
                      ),
                      Text(
                        currentLevel.name,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.trending_up_rounded,
                  size: 28.sp,
                  color: _accentGreen,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Начните покупки для получения уровня',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 20.h),

          // Прогресс-бар
          if (nextLevel != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loyaltyInfo.formattedPurchaseSum,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _primaryGreen,
                  ),
                ),
                Text(
                  _formatAmount(nextLevel.minPurchaseAmount),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 10.h,
                backgroundColor: Colors.black.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(_accentGreen),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 16.sp,
                  color: _accentGreen,
                ),
                SizedBox(width: 4.w),
                Text(
                  'До уровня "${nextLevel.name}": ${loyaltyInfo.formattedAmountToNext}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ] else if (currentLevel != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: _accentGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18.sp,
                    color: _accentGreen,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Максимальный уровень достигнут!',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: _primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context,
    LoyaltyLevelEntity level, {
    bool isCurrentLevel = false,
  }) {
    final color = _parseColor(level.color);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: isCurrentLevel
            ? Border.all(color: color, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isCurrentLevel
                ? color.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isCurrentLevel ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Иконка уровня
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: level.isAchieved
                  ? color.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.1),
              border: Border.all(
                color: level.isAchieved
                    ? color.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                level.icon ?? '🏆',
                style: TextStyle(
                  fontSize: 24.sp,
                  color: level.isAchieved ? null : Colors.grey,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),

          // Информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      level.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: level.isAchieved ? Colors.black87 : Colors.black45,
                      ),
                    ),
                    if (isCurrentLevel) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'Ваш уровень',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  'От ${_formatAmount(level.minPurchaseAmount)}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black45,
                  ),
                ),
                if (level.rewards != null && level.rewards!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: level.rewards!.map((reward) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: level.isAchieved
                              ? color.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          reward.displayDescription,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: level.isAchieved ? color : Colors.black45,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // Статус
          if (level.isAchieved)
            Icon(
              Icons.check_circle_rounded,
              size: 24.sp,
              color: color,
            )
          else
            Icon(
              Icons.lock_outline_rounded,
              size: 24.sp,
              color: Colors.black26,
            ),
        ],
      ),
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return const Color(0xFFFFD700);
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFFFFD700);
    }
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} млн ₸';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} тыс ₸';
    }
    return '$amount ₸';
  }
}
