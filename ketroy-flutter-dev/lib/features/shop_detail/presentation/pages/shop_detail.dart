import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ketroy_app/core/util/launch_url.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/shop/domain/entities/shop_entity.dart';
import 'package:ketroy_app/features/shop_detail/presentation/bloc/shop_detail_bloc.dart';
import 'package:ketroy_app/features/shop_detail/presentation/pages/feedback_sent.dart';
import 'package:ketroy_app/services/analytics/social_analytics_service.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart' show AppLiquidGlassSettings;

class ShopDetail extends StatefulWidget {
  const ShopDetail({super.key, required this.userId, required this.shopData});

  final String userId;
  final ShopEntity shopData;

  @override
  State<ShopDetail> createState() => _ShopDetailState();
}

class _ShopDetailState extends State<ShopDetail>
    with SingleTickerProviderStateMixin {
  // Цвета
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _darkBg = Color(0xFF1A1F12);
  static const Color _cardBg = Color(0xFFF5F7F0);

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _fetchShopReviews();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _fetchShopReviews() {
    context
        .read<ShopDetailBloc>()
        .add(GetShopReviewFetch(shopId: widget.shopData.id));
  }

  Future<void> _navigateAndFetchReviews() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FeedbackSent(
            id: widget.shopData.id,
            userId: widget.userId,
          ),
        ),
      );

      if (!mounted) return;
      _fetchShopReviews();
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Ошибка при переходе к отзывам');
      }
    }
  }

  Uri? _parseUrlSafely(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      return Uri.parse(url);
    } catch (e) {
      return null;
    }
  }

  Future<void> _launchUrlSafely(Uri? url, String serviceName) async {
    if (url == null) {
      showSnackBar(context, '$serviceName недоступен');
      return;
    }
    try {
      await launchURL(url);
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Не удалось открыть $serviceName');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _cardBg,
        body: BlocConsumer<ShopDetailBloc, ShopDetailState>(
          listener: (context, state) {
            if (state.isFailure) showSnackBar(context, state.message ?? '');
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: Loader());
            }
            return _buildContent(state);
          },
        ),
      ),
    );
  }

  Widget _buildContent(ShopDetailState state) {
    final urlWhats = _parseUrlSafely(
        widget.shopData.whatsApp.isNotEmpty == true
            ? 'https://wa.me/${widget.shopData.whatsApp}'
            : null);
    final urlInsta = _parseUrlSafely(widget.shopData.instagram);
    final url2gis = _parseUrlSafely(widget.shopData.twoGisAddress);

    return CustomScrollView(
      slivers: [
        // Изображение с градиентом
        SliverToBoxAdapter(child: _buildHeader()),

        // Информация о магазине
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: _buildInfoCard(),
          ),
        ),

        // Социальные сети
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
            child: _buildSocialLinks(urlWhats, urlInsta, url2gis),
          ),
        ),

        // Отзывы
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _buildReviewsSection(state),
          ),
        ),

        // Кнопка написать отзыв
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 40.h),
            child: _buildReviewButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        // Изображение магазина
        SizedBox(
          height: 280.h,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: widget.shopData.filePath,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: _darkBg,
              child: const Center(child: CompactLoader()),
            ),
            errorWidget: (context, url, error) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_darkBg, _primaryGreen],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.store_rounded,
                  size: 64.w,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),

        // Градиент сверху для статус-бара
        Container(
          height: 120.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Градиент снизу для плавного перехода
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  _cardBg,
                  _cardBg.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),

        // Кнопка назад
        Positioned(
          top: MediaQuery.of(context).padding.top + 8.h,
          left: 16.w,
          child: GestureDetector(
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
        ),

        // Бейдж города
        if (widget.shopData.city.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12.h,
            right: 16.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: _primaryGreen,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, color: _accentGreen, size: 14.w),
                  SizedBox(width: 4.w),
                  Text(
                    widget.shopData.city,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.w),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Название магазина
          Text(
            widget.shopData.name,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),

          // Адрес
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            title: 'Адрес',
            value: widget.shopData.addresses ?? 'Не указан',
          ),

          Divider(height: 24.h, color: Colors.grey.shade200),

          // Режим работы
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            title: 'Режим работы',
            value: widget.shopData.openingHours,
          ),

          Divider(height: 24.h, color: Colors.grey.shade200),

          // Телефон
          _buildInfoRow(
            icon: Icons.phone_outlined,
            title: 'Телефон',
            value: widget.shopData.whatsApp.isNotEmpty
                ? '+${widget.shopData.whatsApp}'
                : 'Не указан',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: _primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: _primaryGreen, size: 20.w),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.black45,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinks(Uri? urlWhats, Uri? urlInsta, Uri? url2gis) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSocialButton(
            icon: 'images/whats.svg',
            label: 'WhatsApp',
            onTap: () {
              // Трекинг клика WhatsApp
              socialAnalytics.trackWhatsAppFromShop(
                shopId: widget.shopData.id,
                shopName: widget.shopData.name,
                city: widget.shopData.city,
                url: urlWhats?.toString(),
              );
              _launchUrlSafely(urlWhats, 'WhatsApp');
            },
            isEnabled: urlWhats != null,
          ),
          _buildSocialButton(
            icon: 'images/2gis.svg',
            label: '2ГИС',
            onTap: () {
              // Трекинг клика 2GIS
              socialAnalytics.track2GisFromShop(
                shopId: widget.shopData.id,
                shopName: widget.shopData.name,
                url: url2gis?.toString(),
              );
              _launchUrlSafely(url2gis, '2ГИС');
            },
            isEnabled: url2gis != null,
          ),
          _buildSocialButton(
            icon: 'images/insta.svg',
            label: 'Instagram',
            onTap: () {
              // Трекинг клика Instagram
              socialAnalytics.trackInstagramFromShop(
                shopId: widget.shopData.id,
                shopName: widget.shopData.name,
                url: urlInsta?.toString(),
              );
              _launchUrlSafely(urlInsta, 'Instagram');
            },
            isEnabled: urlInsta != null,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : () => showSnackBar(context, 'Ссылка недоступна'),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Column(
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Center(
                child: SvgPicture.asset(
                  icon,
                  width: 32.w,
                  height: 32.w,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(ShopDetailState state) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_darkBg, _primaryGreen],
        ),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(Icons.rate_review_rounded, color: _accentGreen, size: 24.w),
              SizedBox(width: 12.w),
              Text(
                'Отзывы',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (state.shopReviewList.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _accentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${state.shopReviewList.length}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: _accentGreen,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 16.h),

          // Отзывы или пустое состояние
          if (state.shopReviewList.isEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 48.w,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Отзывов пока нет',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Будьте первым, кто оставит отзыв!',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...state.shopReviewList
                .take(5)
                .map((review) => _buildReviewCard(review)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Аватар
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_lightGreen, _primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    (review.user?.name ?? 'А').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // Имя и рейтинг
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.user?.name ?? 'Аноним',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    _buildStarRating(review.rating ?? 0),
                  ],
                ),
              ),
            ],
          ),
          if (review.review != null && review.review!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              review.review!,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Padding(
          padding: EdgeInsets.only(right: 2.w),
          child: Icon(
            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 16.w,
            color: index < rating ? Colors.amber : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  Widget _buildReviewButton() {
    return GestureDetector(
      onTap: _navigateAndFetchReviews,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_lightGreen, _primaryGreen],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_rounded, color: Colors.white, size: 20.w),
            SizedBox(width: 10.w),
            Text(
              'Написать отзыв',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
