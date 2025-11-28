import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ketroy_app/core/constants/shop_contacts.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/core/util/launch_url.dart';
import 'package:ketroy_app/features/auth/domain/entities/user_entity.dart';
import 'package:ketroy_app/features/news/presentation/bloc/news_bloc.dart';
import 'package:ketroy_app/features/news/presentation/widgets/video_player_widget.dart';
import 'package:ketroy_app/services/analytics/social_analytics_service.dart';
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:video_player/video_player.dart';

class NewsPageDetail extends StatefulWidget {
  final int id;
  final String text;
  final String? heroImageUrl; // Для Hero-анимации

  const NewsPageDetail({
    super.key,
    required this.text,
    required this.id,
    this.heroImageUrl,
  });

  @override
  State<NewsPageDetail> createState() => _NewsPageDetailState();
}

class _NewsPageDetailState extends State<NewsPageDetail> {
  AuthUserEntity? user;
  Uri? url;

  // Ключ для анализа яркости фона (Anti-Chameleon)
  final _contentBoundaryKey = GlobalKey();

  // Список видеоконтроллеров для управления несколькими видео
  final Map<String, VideoPlayerController> _videoControllers = {};

  // === ScrollController для динамического градиента ===
  late ScrollController _scrollController;
  double _scrollOffset = 0;

  // Высота hero-изображения
  static const double _heroExpandedHeight = 420;
  static const double _heroCollapsedHeight = 280;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    context.read<NewsBloc>().add(GetNewsByIdFetch(id: widget.id));
    _loadUser();
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    }
  }

  Future<void> _loadUser() async {
    try {
      final userData = await UserDataManager.getUser();
      if (mounted) {
        setState(() {
          user = userData;
          _updateUrl();
        });
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  void _updateUrl() {
    if (user?.city == null) {
      url = null;
      return;
    }

    switch (user!.city) {
      case 'Алматы':
        url = WhatsAppContacts.almatyWhatsapp;
        break;
      case 'Астана':
        url = WhatsAppContacts.astanaWhatsapp;
        break;
      case 'Актау':
        url = WhatsAppContacts.aqtauWhatsapp;
        break;
      case 'Шымкент':
        url = WhatsAppContacts.shymkentWhatsapp;
        break;
      default:
        url = null;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _disposeVideoControllers();
    super.dispose();
  }

  void _disposeVideoControllers() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
  }

  bool _isVideoFile(String url) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v'];
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowerUrl.contains(ext));
  }

  // Вычисляем прогресс сворачивания (0 = развёрнуто, 1 = свёрнуто)
  double get _collapseProgress {
    const maxScroll = 150.0;
    return (_scrollOffset / maxScroll).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: BlocBuilder<NewsBloc, NewsState>(
        builder: (BuildContext context, NewsState state) {
          if (state.isLoading) {
            return _buildLoadingState();
          }
          if (state.isFailure) {
            return _buildScrollableErrorWidget(
                state.error ?? 'Ошибка загрузки');
          }

          final newsDetail = state.newsDetail;
          if (newsDetail == null || newsDetail.blocks.isEmpty) {
            return _buildEmptyContentWidget();
          }

          final filteredBlocks = newsDetail.blocks
              .where((block) =>
                  (block.mediaPath != null && block.mediaPath!.isNotEmpty) ||
                  (block.text != null && block.text!.isNotEmpty))
              .toList();

          if (filteredBlocks.isEmpty) {
            return _buildEmptyContentWidget();
          }

          // Находим первый блок с изображением для hero
          String? heroImagePath = widget.heroImageUrl;
          int heroBlockIndex = -1;

          if (heroImagePath == null) {
            for (int i = 0; i < filteredBlocks.length; i++) {
              final block = filteredBlocks[i];
              if (block.mediaPath != null &&
                  block.mediaPath!.isNotEmpty &&
                  !_isVideoFile(block.mediaPath!)) {
                heroImagePath = block.mediaPath;
                heroBlockIndex = i;
                break;
              }
            }
          } else {
            // Находим индекс hero-блока по URL
            for (int i = 0; i < filteredBlocks.length; i++) {
              if (filteredBlocks[i].mediaPath == heroImagePath) {
                heroBlockIndex = i;
                break;
              }
            }
          }

          return Stack(
            children: [
              // === Основной контент с RepaintBoundary для Anti-Chameleon ===
              RepaintBoundary(
                key: _contentBoundaryKey,
                child: RefreshIndicator(
                  onRefresh: () async {
                    _disposeVideoControllers();
                    context
                        .read<NewsBloc>()
                        .add(GetNewsByIdFetch(id: widget.id));
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  edgeOffset: 100,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // === Hero Image с динамическим градиентом ===
                      if (heroImagePath != null)
                        SliverToBoxAdapter(
                          child: _buildDynamicHeroImage(heroImagePath),
                        ),

                      // === Заголовок ===
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 8.h),
                          child: Text(
                            widget.text,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                              height: 1.25,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),

                      // === Разделитель ===
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Container(
                            height: 3,
                            width: 60.w,
                            decoration: BoxDecoration(
                              color: AppTheme.brandColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),

                      // === Контент блоков ===
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 120.h),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final block = filteredBlocks[index];

                              // Пропускаем hero-изображение, оно уже показано
                              final bool isHeroBlock = index == heroBlockIndex;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Медиа контент (кроме hero)
                                  if (!isHeroBlock &&
                                      block.mediaPath != null &&
                                      block.mediaPath!.isNotEmpty) ...[
                                    _buildMediaContent(
                                        block.mediaPath!, block.resolution),
                                    SizedBox(height: 16.h),
                                  ],

                                  // Текст блока
                                  if (block.text != null &&
                                      block.text!.isNotEmpty) ...[
                                    Text(
                                      block.text!,
                                      style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF3D3D3D),
                                        height: 1.6,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                  ],
                                ],
                              );
                            },
                            childCount: filteredBlocks.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // === Liquid Glass кнопка "Назад" ===
              Positioned(
                top: MediaQuery.of(context).padding.top + 8.h,
                left: 16.w,
                child: _LiquidGlassBackButton(
                  contentKey: _contentBoundaryKey,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),

              // === Liquid Glass FAB WhatsApp ===
              if (url != null)
                Positioned(
                  bottom: 24.h + MediaQuery.of(context).padding.bottom,
                  right: 20.w,
                  child: _LiquidGlassWhatsAppFAB(
                    contentKey: _contentBoundaryKey,
                    onTap: () {
                      if (url != null) {
                        // Трекинг клика WhatsApp со страницы новости
                        socialAnalytics.trackWhatsAppFromNews(
                          newsId: widget.id,
                          newsTitle: widget.text,
                          city: user?.city,
                          url: url.toString(),
                        );
                        launchURL(url!);
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Loading state с Hero placeholder для плавного перехода
  Widget _buildLoadingState() {
    return Stack(
      children: [
        // Hero placeholder
        if (widget.heroImageUrl != null)
          Hero(
            tag: 'news_image_${widget.id}',
            child: CachedNetworkImage(
              imageUrl: widget.heroImageUrl!,
              width: double.infinity,
              height: _heroExpandedHeight.h,
              fit: BoxFit.cover,
            ),
          ),
        // Gradient overlay
        if (widget.heroImageUrl != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _heroExpandedHeight.h,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white,
                  ],
                  stops: const [0.5, 0.8, 1.0],
                ),
              ),
            ),
          ),
        // Loading indicator
        Positioned.fill(
          child: Center(
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: const CompactLoader(),
            ),
          ),
        ),
        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8.h,
          left: 16.w,
          child: _LiquidGlassBackButton(
            contentKey: _contentBoundaryKey,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  /// Hero Image с динамическим градиентом при скролле
  Widget _buildDynamicHeroImage(String imagePath) {
    // Интерполируем высоту изображения при скролле
    final currentHeight = ui.lerpDouble(
      _heroExpandedHeight.h,
      _heroCollapsedHeight.h,
      _collapseProgress,
    )!;

    // Интенсивность градиента увеличивается при скролле
    final gradientOpacity = ui.lerpDouble(0.0, 0.7, _collapseProgress)!;
    final fogOpacity = ui.lerpDouble(0.0, 0.4, _collapseProgress)!;

    return SizedBox(
      height: currentHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Hero Image
          Hero(
            tag: 'news_image_${widget.id}',
            child: CachedNetworkImage(
              imageUrl: imagePath,
              width: double.infinity,
              height: currentHeight,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: const Color(0xFFF5F5F5),
                child: const Center(child: CompactLoader()),
              ),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFFF5F5F5),
                child: Icon(Icons.broken_image,
                    size: 48.sp, color: Colors.grey[400]),
              ),
            ),
          ),

          // === Динамический туман/градиент при скролле ===
          // Верхний туман (появляется при скролле)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: currentHeight * 0.4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: fogOpacity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Нижний градиент (плавный переход к контенту)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: currentHeight * 0.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.3 + gradientOpacity * 0.5),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // === Виньетка по краям (усиливается при скролле) ===
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: gradientOpacity * 0.3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(String mediaPath, String? resolution) {
    if (_isVideoFile(mediaPath)) {
      return _buildVideoPlayer(mediaPath, resolution);
    } else {
      return _buildImageContent(mediaPath);
    }
  }

  Widget _buildImageContent(String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: CachedNetworkImage(
        imageUrl: imagePath,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: const Center(child: CompactLoader()),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 40.sp, color: Colors.grey[400]),
              SizedBox(height: 8.h),
              Text(
                'Не удалось загрузить',
                style: TextStyle(color: Colors.grey[500], fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(String videoPath, String? resolution) {
    if (!_videoControllers.containsKey(videoPath)) {
      _videoControllers[videoPath] = VideoPlayerController.networkUrl(
        Uri.parse(videoPath),
      );
    }

    final controller = _videoControllers[videoPath]!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: AspectRatio(
        aspectRatio: resolution == 'portrait' ? 9 / 16 : 16 / 9,
        child: VideoPlayerWidget(
          controller: controller,
          videoPath: videoPath,
          resolution: resolution,
        ),
      ),
    );
  }

  Widget _buildScrollableErrorWidget(String error) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<NewsBloc>().add(GetNewsByIdFetch(id: widget.id));
        await Future.delayed(const Duration(seconds: 1));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline,
                      size: 48.sp, color: Colors.red[400]),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Ошибка загрузки',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 8.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Text(
                    error,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 24.h),
                GestureDetector(
                  onTap: () => context
                      .read<NewsBloc>()
                      .add(GetNewsByIdFetch(id: widget.id)),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppTheme.brandColor,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Text(
                      'Повторить',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContentWidget() {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<NewsBloc>().add(GetNewsByIdFetch(id: widget.id));
        await Future.delayed(const Duration(seconds: 1));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.article_outlined,
                      size: 48.sp, color: Colors.grey[400]),
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Контент не найден',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LIQUID GLASS BACK BUTTON с Anti-Chameleon
// ============================================================================

class _LiquidGlassBackButton extends StatefulWidget {
  final GlobalKey? contentKey;
  final VoidCallback onTap;

  const _LiquidGlassBackButton({
    required this.onTap,
    this.contentKey,
  });

  @override
  State<_LiquidGlassBackButton> createState() => _LiquidGlassBackButtonState();
}

class _LiquidGlassBackButtonState extends State<_LiquidGlassBackButton> {
  bool _isDarkBackground = false;
  Timer? _luminanceTimer;

  // Цвета для светлого фона (тёмная иконка)
  static const Color _darkIconColor = Color(0xFF2D2D2D);

  // Цвета для тёмного фона (светлая иконка)
  static const Color _lightIconColor = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _startLuminanceAnalysis();
  }

  @override
  void dispose() {
    _luminanceTimer?.cancel();
    super.dispose();
  }

  void _startLuminanceAnalysis() {
    _luminanceTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _analyzeLuminance();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _analyzeLuminance());
  }

  Future<void> _analyzeLuminance() async {
    if (!mounted || widget.contentKey == null) return;

    try {
      final boundary = widget.contentKey!.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null || !boundary.hasSize) return;
      
      // Проверяем, что рендеринг завершён
      if (boundary.debugNeedsPaint) return;

      final image = await boundary.toImage(pixelRatio: 0.1);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData == null) return;

      final width = image.width;
      final height = image.height;

      // Анализируем верхний левый угол (где находится кнопка)
      final areaWidth = (width * 0.15).toInt();
      final areaHeight = (height * 0.1).toInt();

      double totalLuminance = 0;
      int pixelCount = 0;

      for (int y = 0; y < areaHeight; y++) {
        for (int x = 0; x < areaWidth; x++) {
          final offset = (y * width + x) * 4;
          if (offset + 3 < byteData.lengthInBytes) {
            final r = byteData.getUint8(offset);
            final g = byteData.getUint8(offset + 1);
            final b = byteData.getUint8(offset + 2);

            final luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
            totalLuminance += luminance;
            pixelCount++;
          }
        }
      }

      if (pixelCount == 0) return;

      final avgLuminance = totalLuminance / pixelCount;
      final isDark = avgLuminance < 0.5;

      if (mounted && isDark != _isDarkBackground) {
        setState(() {
          _isDarkBackground = isDark;
        });
      }

      image.dispose();
    } catch (e) {
      debugPrint('Back button luminance analysis error: $e');
    }
  }

  Color get _iconColor => _isDarkBackground ? _lightIconColor : _darkIconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: LiquidGlass.withOwnLayer(
        shape: LiquidRoundedSuperellipse(borderRadius: 14.r),
        child: SizedBox(
          width: 44.w,
          height: 44.h,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              key: ValueKey(_isDarkBackground),
              size: 20.sp,
              color: _iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// LIQUID GLASS WHATSAPP FAB с Anti-Chameleon
// ============================================================================

class _LiquidGlassWhatsAppFAB extends StatefulWidget {
  final GlobalKey? contentKey;
  final VoidCallback onTap;

  const _LiquidGlassWhatsAppFAB({
    required this.onTap,
    this.contentKey,
  });

  @override
  State<_LiquidGlassWhatsAppFAB> createState() =>
      _LiquidGlassWhatsAppFABState();
}

class _LiquidGlassWhatsAppFABState extends State<_LiquidGlassWhatsAppFAB>
    with SingleTickerProviderStateMixin {
  bool _isDarkBackground = false;
  Timer? _luminanceTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // WhatsApp brand color
  static const Color _whatsAppGreen = Color(0xFF25D366);

  // Цвета для светлого фона
  static const Color _darkIconColor = Color(0xFF128C7E);

  // Цвета для тёмного фона
  static const Color _lightIconColor = Color(0xFF25D366);

  @override
  void initState() {
    super.initState();
    _startLuminanceAnalysis();

    // Анимация пульсации для привлечения внимания
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _luminanceTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startLuminanceAnalysis() {
    _luminanceTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _analyzeLuminance();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _analyzeLuminance());
  }

  Future<void> _analyzeLuminance() async {
    if (!mounted || widget.contentKey == null) return;

    try {
      final boundary = widget.contentKey!.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null || !boundary.hasSize) return;
      
      // Проверяем, что рендеринг завершён
      if (boundary.debugNeedsPaint) return;

      final image = await boundary.toImage(pixelRatio: 0.1);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData == null) return;

      final width = image.width;
      final height = image.height;

      // Анализируем нижний правый угол (где находится FAB)
      final areaWidth = (width * 0.2).toInt();
      final areaHeight = (height * 0.15).toInt();

      double totalLuminance = 0;
      int pixelCount = 0;

      for (int y = height - areaHeight; y < height; y++) {
        for (int x = width - areaWidth; x < width; x++) {
          final offset = (y * width + x) * 4;
          if (offset + 3 < byteData.lengthInBytes) {
            final r = byteData.getUint8(offset);
            final g = byteData.getUint8(offset + 1);
            final b = byteData.getUint8(offset + 2);

            final luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
            totalLuminance += luminance;
            pixelCount++;
          }
        }
      }

      if (pixelCount == 0) return;

      final avgLuminance = totalLuminance / pixelCount;
      final isDark = avgLuminance < 0.5;

      if (mounted && isDark != _isDarkBackground) {
        setState(() {
          _isDarkBackground = isDark;
        });
      }

      image.dispose();
    } catch (e) {
      debugPrint('WhatsApp FAB luminance analysis error: $e');
    }
  }

  Color get _iconColor => _isDarkBackground ? _lightIconColor : _darkIconColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // Более мягкий и деликатный glow
              BoxShadow(
                color: _whatsAppGreen.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: LiquidGlass.withOwnLayer(
            shape: LiquidRoundedSuperellipse(borderRadius: 30.r),
            child: SizedBox(
              width: 60.w,
              height: 60.h,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  // Сдвигаем иконку на 2 пикселя вправо для центрирования
                  child: Padding(
                    padding: EdgeInsets.only(left: 2.w),
                    child: SvgPicture.asset(
                      'images/whats2.svg',
                      key: ValueKey(_isDarkBackground),
                      width: 30.w,
                      height: 30.h,
                      colorFilter: ColorFilter.mode(
                        _iconColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAGE ROUTE с Hero-анимацией для открытия новости
// ============================================================================

class NewsDetailPageRoute extends PageRouteBuilder {
  final int newsId;
  final String newsTitle;
  final String? heroImageUrl;

  NewsDetailPageRoute({
    required this.newsId,
    required this.newsTitle,
    this.heroImageUrl,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              NewsPageDetail(
            id: newsId,
            text: newsTitle,
            heroImageUrl: heroImageUrl,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Комбинируем fade и scale для эффекта "расширения"
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ));

            final scaleAnimation = Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}
