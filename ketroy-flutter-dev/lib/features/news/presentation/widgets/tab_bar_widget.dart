import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/features/news/presentation/bloc/news_bloc.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

class TabBarWidget extends StatelessWidget {
  final NewsState state;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;
  const TabBarWidget({
    super.key,
    required this.state,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  // Цвет фона витрины (как на странице профиля)
  static const Color _cardBg = Color(0xFFF5F7F0);
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: _cardBg,
      padding: EdgeInsets.only(top: 0, bottom: 16.h),
      child: SingleChildScrollView(
        key: const PageStorageKey('newsTabBarScroll'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: 16.w,
            ),
            _AnimatedCategoryButton(
              label: l10n.all,
              isSelected: selectedIndex == 0,
              onTap: () => onCategorySelected(0),
            ),
            SizedBox(
              width: 18.w,
            ),
            ...List.generate(state.categoriesList.length, (index) {
              final category = state.categoriesList[index];
              return Row(
                children: [
                  _AnimatedCategoryButton(
                    label: category.name,
                    isSelected: selectedIndex == index + 1,
                    onTap: () => onCategorySelected(index + 1),
                  ),
                  SizedBox(width: 18.w),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCategoryButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedCategoryButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnimatedCategoryButton> createState() =>
      _AnimatedCategoryButtonState();
}

class _AnimatedCategoryButtonState extends State<_AnimatedCategoryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          width: 94.w,
          height: 41.h,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF3C4B1B)
                : (_isPressed ? const Color(0xFFF5F5F5) : Colors.transparent),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFF3C4B1B)
                  : Colors.black.withValues(alpha: 0.12),
              width: widget.isSelected ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(13.r),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF3C4B1B).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              style: AppTheme.newsMediumTextStyle.copyWith(
                color: widget.isSelected ? Colors.white : Colors.black,
                fontWeight:
                    widget.isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}
