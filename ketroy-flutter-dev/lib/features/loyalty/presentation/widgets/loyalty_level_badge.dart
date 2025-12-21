import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/features/loyalty/presentation/bloc/loyalty_bloc.dart';
import 'package:ketroy_app/features/loyalty/presentation/pages/levels_screen.dart';
import 'package:ketroy_app/core/transitions/slide_over_page_route.dart';
import 'package:ketroy_app/init_dependencies.dart';

/// Бейдж с уровнем лояльности для отображения в профиле
/// Самостоятельно получает LoyaltyBloc из serviceLocator
class LoyaltyLevelBadge extends StatelessWidget {
  final bool compact;
  final VoidCallback? onTap;

  const LoyaltyLevelBadge({
    super.key,
    this.compact = false,
    this.onTap,
  });

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return const Color(0xFFFFD700);
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFFFFD700);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Получаем блок из serviceLocator и предоставляем его
    return BlocProvider.value(
      value: serviceLocator<LoyaltyBloc>(),
      child: BlocBuilder<LoyaltyBloc, LoyaltyState>(
        builder: (context, state) {
          // Не показываем если нет информации или загрузка
          if (state.status == LoyaltyStatus.loading) {
            return SizedBox(
              height: 24.h,
              child: Center(
                child: SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            );
          }

          final currentLevel = state.loyaltyInfo?.currentLevel;

          // Если нет уровня - показываем приглашение
          if (currentLevel == null) {
            return _buildNoLevelBadge(context);
          }

          final levelColor = _parseColor(currentLevel.color);

          return GestureDetector(
            onTap: onTap ?? () => _navigateToLevels(context),
            child: compact
                ? _buildCompactBadge(currentLevel, levelColor)
                : _buildFullBadge(currentLevel, levelColor, state),
          );
        },
      ),
    );
  }

  Widget _buildNoLevelBadge(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToLevels(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 16.sp,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            SizedBox(width: 6.w),
            Text(
              'Получите уровень',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.chevron_right_rounded,
              size: 16.sp,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactBadge(dynamic level, Color levelColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: levelColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: levelColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            level.icon ?? '🏆',
            style: TextStyle(fontSize: 14.sp),
          ),
          SizedBox(width: 4.w),
          Text(
            level.name,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBadge(dynamic level, Color levelColor, LoyaltyState state) {
    final progress = state.loyaltyInfo?.progressPercent ?? 0;
    final nextLevel = state.loyaltyInfo?.nextLevel;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            levelColor.withValues(alpha: 0.25),
            levelColor.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: levelColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            level.icon ?? '🏆',
            style: TextStyle(fontSize: 18.sp),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                level.name,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (nextLevel != null) ...[
                SizedBox(height: 2.h),
                Row(
                  children: [
                    SizedBox(
                      width: 60.w,
                      height: 4.h,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2.r),
                        child: LinearProgressIndicator(
                          value: (progress / 100).clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${progress.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          SizedBox(width: 8.w),
          Icon(
            Icons.chevron_right_rounded,
            size: 18.sp,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  void _navigateToLevels(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      SlideOverPageRoute(page: const LevelsScreen()),
    );
  }
}
