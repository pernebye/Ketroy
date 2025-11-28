import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/features/news/domain/entities/banners_list_entity.dart';

class Carousel extends StatefulWidget {
  const Carousel({
    super.key,
    required this.controller,
    required this.bannerList,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 3),
  });

  final CarouselSliderController controller;
  final bool autoPlay;
  final List<BannersListEntity> bannerList;
  final Duration autoPlayInterval;

  @override
  State<Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> with TickerProviderStateMixin {
  // Цвета для индикатора
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  
  int currentIndex = 0;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.autoPlayInterval,
    );
    if (widget.autoPlay && widget.bannerList.length > 1) {
      _progressController.forward();
      _progressController.addStatusListener(_onProgressComplete);
    }
  }

  @override
  void dispose() {
    _progressController.removeStatusListener(_onProgressComplete);
    _progressController.dispose();
    super.dispose();
  }

  void _onProgressComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _onPageChanged(int index) {
    if (mounted) {
      setState(() {
        currentIndex = index;
      });
      if (widget.autoPlay && widget.bannerList.length > 1) {
        _progressController.reset();
        _progressController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Проверяем, есть ли баннеры
    if (widget.bannerList.isEmpty) {
      return _buildEmptyState();
    }
    return Stack(
      children: [
        _buildCarousel(),
        _buildModernIndicator(),
      ],
    );
  }

  Widget _buildModernIndicator() {
    if (widget.bannerList.length <= 1) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      bottom: 24.h,
      left: 20.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.bannerList.length, (index) {
            final isActive = index == currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              child: _buildIndicatorItem(index, isActive),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildIndicatorItem(int index, bool isActive) {
    // Градиент: 60% тёмно-зелёный, 40% светло-зелёный
    const indicatorGradient = LinearGradient(
      colors: [_primaryGreen, _primaryGreen, _accentGreen],
      stops: [0.0, 0.6, 1.0],
    );
    
    if (isActive && widget.autoPlay) {
      // Активный элемент с прогрессом
      return AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return Container(
            width: 24.w,
            height: 4.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.r),
              color: Colors.white.withValues(alpha: 0.3),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 24.w * _progressController.value,
                height: 4.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2.r),
                  gradient: indicatorGradient,
                ),
              ),
            ),
          );
        },
      );
    } else if (isActive) {
      // Активный без автопрокрутки
      return Container(
        width: 24.w,
        height: 4.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2.r),
          gradient: indicatorGradient,
        ),
      );
    } else {
      // Неактивный элемент
      return Container(
        width: 8.w,
        height: 4.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2.r),
          color: Colors.white.withValues(alpha: 0.5),
        ),
      );
    }
  }

  Widget _buildImage(String filePath) {
    // Проверяем валидность URL
    if (filePath.isEmpty || !_isValidUrl(filePath)) {
      return _buildErrorWidget();
    }

    if (_isGif(filePath)) {
      return Image.network(
        filePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingWidget();
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Ошибка загрузки GIF: $error');
          return _buildErrorWidget();
        },
      ); // Или Gif() если используешь gif-плеер
    } else {
      return CachedNetworkImage(
        imageUrl: filePath,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) =>
            _buildLoadingWidget(), // Заглушка при загрузке
        errorWidget: (context, url, error) {
          debugPrint('Ошибка загрузки изображения: $error');
          return _buildErrorWidget();
        }, // Ошибка загрузки
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 300),
        // memCacheWidth: (MediaQuery.of(context).size.width).round(),
      );
    }
  }

  Widget _buildCarousel() {
    return CarouselSlider.builder(
        carouselController: widget.controller,
        itemCount: widget.bannerList.length,
        itemBuilder: (context, index, realIndex) {
          final banner = widget.bannerList[index];
          return _buildCarouselItem(banner, index);
        },
        options: CarouselOptions(
          // height: 580.h,
          aspectRatio: 3 / 4,
          viewportFraction: 1.0,
          autoPlay: widget.autoPlay,
          autoPlayInterval: widget.autoPlayInterval,
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          autoPlayCurve: Curves.fastOutSlowIn,
          enlargeCenterPage: false,
          scrollDirection: Axis.horizontal,
          onPageChanged: (index, reason) => _onPageChanged(index),
        ));
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3C4B1B)),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Ошибка загрузки',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // CarouselSlider(
  //       carouselController: widget.controller,
  //       items: widget.bannerList.map((i) {
  //         return Builder(
  //           builder: (BuildContext context) {
  //             return Container(
  //                 width: 346.w,
  //                 margin: EdgeInsets.symmetric(horizontal: 2.5.w),
  //                 decoration:
  //                     BoxDecoration(borderRadius: BorderRadius.circular(13.r)),
  //                 child: ClipRRect(
  //                     borderRadius: BorderRadius.circular(13.r),
  //                     child: buildImage(i.filePath)));
  //           },
  //         );
  //       }).toList(),
  //       options: CarouselOptions(
  //         aspectRatio: 1,
  //         viewportFraction: 0.8,
  //         autoPlay: false,
  //         enlargeCenterPage: false,
  //         onPageChanged: (index, reason) {
  //           setState(() {
  //             currentIndex = index;
  //           });
  //         },
  //       ),
  //     ),

  Widget _buildCarouselItem(BannersListEntity banner, int index) {
    return Container(
        width: double.infinity,
        // margin: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(banner.filePath),
            // _buildContentOverlay(banner),
          ],
        ));
  }

  Widget _buildEmptyState() {
    return Container(
      height: 377.h,
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.symmetric(horizontal: 22.w),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(13.r),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Нет доступных баннеров',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  bool _isGif(String url) {
    return url.toLowerCase().endsWith('.gif');
  }
}
