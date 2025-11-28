import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/features/shop/domain/entities/shop_entity.dart';
import 'package:ketroy_app/features/shop/presentation/bloc/shop_bloc.dart';
import 'package:ketroy_app/features/shop_detail/presentation/bloc/shop_detail_bloc.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

class WriteReviewSheet extends StatefulWidget {
  final String userId;

  const WriteReviewSheet({
    super.key,
    required this.userId,
  });

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet>
    with SingleTickerProviderStateMixin {
  // Цвета
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _cardBg = Color(0xFFF5F7F0);

  final TextEditingController _reviewController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  ShopEntity? _selectedShop;
  int _rating = 0;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();

    // Загружаем список магазинов (все города)
    context.read<ShopBloc>().add(const GetShopListFetch(city: null));
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return BlocListener<ShopDetailBloc, ShopDetailState>(
      listener: (context, state) {
        if (state.isSendSuccess) {
          setState(() => _isLoading = false);
          Navigator.pop(context);
          showSnackBar(context, l10n.reviewSentSuccess);
        } else if (state.isFailure) {
          setState(() => _isLoading = false);
          showSnackBar(context, l10n.reviewSentError);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Хэндл
            _buildHandle(),
            
            // Заголовок
            _buildHeader(l10n),
            
            // Контент
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                child: Column(
                  children: [
                    // Выбор магазина
                    _buildShopSelector(l10n),
                    
                    SizedBox(height: 20.h),
                    
                    // Рейтинг
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                      child: _buildRatingSection(l10n),
                    ),
                    
                    SizedBox(height: 20.h),
                    
                    // Текст отзыва
                    _buildReviewInput(l10n),
                    
                    SizedBox(height: 24.h),
                    
                    // Кнопка отправить
                    _buildSubmitButton(l10n),
                    
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accentGreen.withValues(alpha: 0.2),
                  _primaryGreen.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.rate_review_rounded,
              color: _primaryGreen,
              size: 24.w,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.writeReview,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  l10n.shareYourExperience,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 20.w,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopSelector(AppLocalizations l10n) {
    return BlocBuilder<ShopBloc, ShopState>(
      builder: (context, state) {
        final shops = state.shopList;
        
        return GestureDetector(
          onTap: () => _showShopPicker(shops, l10n),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: _selectedShop != null 
                    ? _primaryGreen 
                    : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: _primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.store_rounded,
                    color: _primaryGreen,
                    size: 22.w,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedShop?.name ?? l10n.selectShop,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: _selectedShop != null 
                              ? FontWeight.w600 
                              : FontWeight.w400,
                          color: _selectedShop != null 
                              ? Colors.black87 
                              : Colors.black45,
                        ),
                      ),
                      if (_selectedShop != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          _selectedShop!.city,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.black45,
                  size: 24.w,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showShopPicker(List<ShopEntity> shops, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: 500.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Хэндл
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            // Заголовок
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Icon(
                    Icons.store_rounded,
                    color: _primaryGreen,
                    size: 24.w,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    l10n.selectShop,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            Divider(height: 1, color: Colors.grey.shade200),
            
            // Список магазинов
            Flexible(
              child: shops.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.store_outlined,
                              size: 48.w,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              l10n.noShopsFound,
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: shops.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 72.w,
                        color: Colors.grey.shade100,
                      ),
                      itemBuilder: (context, index) {
                        final shop = shops[index];
                        final isSelected = _selectedShop?.id == shop.id;
                        
                        return ListTile(
                          onTap: () {
                            setState(() => _selectedShop = shop);
                            Navigator.pop(context);
                          },
                          leading: Container(
                            width: 48.w,
                            height: 48.w,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primaryGreen.withValues(alpha: 0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.network(
                                shop.filePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.store_rounded,
                                  color: isSelected ? _primaryGreen : Colors.grey,
                                  size: 24.w,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            shop.name,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected ? _primaryGreen : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            shop.city,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.black45,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: _primaryGreen,
                                  size: 24.w,
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.rateShop,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          
          SizedBox(height: 8.h),
          
          Text(
            _getRatingText(l10n),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black45,
            ),
          ),
          
          SizedBox(height: 16.h),
          
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
                    isSelected 
                        ? Icons.star_rounded 
                        : Icons.star_outline_rounded,
                    size: 40.w,
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

  String _getRatingText(AppLocalizations l10n) {
    switch (_rating) {
      case 1:
        return l10n.ratingVeryBad;
      case 2:
        return l10n.ratingBad;
      case 3:
        return l10n.ratingNormal;
      case 4:
        return l10n.ratingGood;
      case 5:
        return l10n.ratingExcellent;
      default:
        return l10n.tapStarsToRate;
    }
  }

  Widget _buildReviewInput(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _focusNode.hasFocus ? _primaryGreen : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _reviewController,
        focusNode: _focusNode,
        maxLines: 4,
        style: TextStyle(
          fontSize: 15.sp,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: l10n.reviewHint,
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
    );
  }

  Widget _buildSubmitButton(AppLocalizations l10n) {
    final isEnabled = _selectedShop != null && 
                      _reviewController.text.isNotEmpty && 
                      _rating > 0;

    return GestureDetector(
      onTap: isEnabled && !_isLoading ? _submitReview : null,
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
          child: _isLoading
              ? SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
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
                      l10n.sendReview,
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

  void _submitReview() {
    if (_selectedShop == null) return;
    
    setState(() => _isLoading = true);
    
    context.read<ShopDetailBloc>().add(
      SendShopReviewFetch(
        shopId: _selectedShop!.id.toString(),
        userId: widget.userId,
        review: _reviewController.text,
        rating: _rating.toString(),
      ),
    );
  }
}

