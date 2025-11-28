import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/features/news/domain/entities/news_list_entity.dart';
import 'package:ketroy_app/features/news/presentation/bloc/news_bloc.dart';
import 'package:ketroy_app/features/news/presentation/pages/news_page_detail.dart';
import 'package:ketroy_app/features/news/presentation/widgets/carousle.dart';
import 'package:ketroy_app/features/news/presentation/widgets/skeleton_box.dart';
import 'package:ketroy_app/features/news/presentation/widgets/stories.dart';
import 'package:ketroy_app/features/news/presentation/widgets/tab_bar_widget.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:ketroy_app/services/shared_preferences_service.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

class NewsPage extends StatefulWidget {
  final Function(bool shouldExtendBehindAppBar)? onScrollModeChanged;
  const NewsPage({super.key, this.onScrollModeChanged});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> with TickerProviderStateMixin {
  // Цвет фона витрины (как на странице профиля)
  static const Color _cardBg = Color(0xFFF5F7F0);
  
  late CarouselSliderController controller;
  late ScrollController scrollController;
  late AnimationController _shimmerController;
  late AnimationController _contentAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int selectedIndex = 0;
  int selectedTab = 0;
  final double scrollThreshold = 500.0;
  final sharedService = serviceLocator<SharedPreferencesService>();

  bool _lastExtendBehindAppBar = true;

  // Переменные для пагинации
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String _selectedCategory = '';

  // Все новости для локальной фильтрации
  final List<NewsListEntity> _allNews = [];
  List<NewsListEntity> _filteredNews = [];

  // Предзагруженные изображения
  final Set<String> _precachedImages = {};

  @override
  void initState() {
    super.initState();
    controller = CarouselSliderController();
    scrollController = ScrollController();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Анимация для контента при переключении категорий
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _contentAnimationController.forward();

    _initializeData();
    _setupScrollListener();
  }

  void _initializeData() {
    final newsBloc = context.read<NewsBloc>();
    newsBloc
      ..add(GetBannersListFetch())
      ..add(const GetNewsListFetch())
      ..add(GetCategoriesListFetch())
      ..add(const GetActualsFetch());

    if (!sharedService.deviceTokenPassed) {
      newsBloc.add(const PostDeviceTokenFetch());
    }
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      final currentOffset = scrollController.offset;
      final shouldExtendBehindAppBar = currentOffset < scrollThreshold;

      // Уведомляем NavScreen только при изменении состояния
      if (shouldExtendBehindAppBar != _lastExtendBehindAppBar) {
        _lastExtendBehindAppBar = shouldExtendBehindAppBar;
        widget.onScrollModeChanged?.call(shouldExtendBehindAppBar);

        debugPrint(
            'NewsPage: Scroll ${currentOffset.toInt()}px - extendBodyBehindAppBar: $shouldExtendBehindAppBar');
      }

      // Проверка для пагинации
      _checkForPagination();
    });
  }

  void _checkForPagination() {
    if (_isLoadingMore || !_hasMoreData) return;

    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    const delta = 200.0; // Триггер за 200px до конца

    if (maxScroll - currentScroll <= delta) {
      _loadMoreNews();
    }
  }

  void _loadMoreNews() {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    // Всегда загружаем ВСЕ новости (без фильтра), фильтрация локальная
    context
        .read<NewsBloc>()
        .add(GetNewsListFetch(page: _currentPage, isLoadMore: true));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _contentAnimationController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // Метод для обработки обновления
  Future<void> _handleRefresh() async {
    try {
      // Сбрасываем локальный кэш
      setState(() {
        _allNews.clear();
        _filteredNews.clear();
        _currentPage = 1;
        _hasMoreData = true;
        selectedIndex = 0;
        _selectedCategory = '';
      });

      final newsBloc = context.read<NewsBloc>();
      newsBloc.add(ResetNewsStateFetch());

      await Future.delayed(const Duration(milliseconds: 200));
      _initializeData();
    } catch (e) {
      debugPrint('Error during refresh: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        showSnackBar(context, l10n?.refreshError ?? 'Ошибка обновления данных');
      }
    }

    await Future.delayed(const Duration(seconds: 2));
  }

  // Простое переключение категории — локальная фильтрация
  void _onCategoryChanged(int index, NewsState state) {
    if (selectedIndex == index) return;

    setState(() {
      selectedIndex = index;

      if (index == 0) {
        // All — показываем все
        _selectedCategory = '';
        _filteredNews = List.from(_allNews);
      } else {
        // Фильтруем по категории
        _selectedCategory = state.categoriesList[index - 1].name;
        _filteredNews = _allNews
            .where((news) => news.category == _selectedCategory)
            .toList();
      }
    });

    // Предзагружаем изображения для новой категории (первые 5)
    for (final news in _filteredNews.take(5)) {
      _precacheNewsImage(news);
    }

    // Плавная анимация появления отфильтрованного контента
    _contentAnimationController.forward(from: 0.0);
  }

  // Обновление списка всех новостей при загрузке
  void _updateAllNews(List<NewsListEntity> news) {
    // Добавляем новые новости, избегая дубликатов
    final existingIds = _allNews.map((n) => n.id).toSet();
    for (final item in news) {
      if (!existingIds.contains(item.id)) {
        _allNews.add(item);
      }
    }

    // Обновляем отфильтрованный список
    if (_selectedCategory.isEmpty) {
      _filteredNews = List.from(_allNews);
    } else {
      _filteredNews =
          _allNews.where((n) => n.category == _selectedCategory).toList();
    }

    // Предзагружаем изображения для всех категорий
    _precacheImagesForAllCategories();
  }

  // Предзагрузка первых изображений каждой категории
  Future<void> _precacheImagesForAllCategories() async {
    if (!mounted) return;

    // Собираем уникальные категории
    final categories = _allNews.map((n) => n.category).toSet();

    for (final category in categories) {
      // Получаем первые 3 новости каждой категории
      final categoryNews =
          _allNews.where((n) => n.category == category).take(3).toList();

      for (final news in categoryNews) {
        _precacheNewsImage(news);
      }
    }

    // Также предзагружаем первые 5 из "All"
    for (final news in _allNews.take(5)) {
      _precacheNewsImage(news);
    }
  }

  // Предзагрузка одного изображения
  void _precacheNewsImage(NewsListEntity news) {
    if (news.blocks.isEmpty) return;

    final imagePath = news.blocks[0].mediaPath;
    if (imagePath == null || imagePath.isEmpty) return;

    // Пропускаем видео
    if (imagePath.contains('.mp4') || imagePath.contains('.mov')) return;

    // Проверяем, не загружено ли уже
    if (_precachedImages.contains(imagePath)) return;

    _precachedImages.add(imagePath);

    // Предзагружаем в фоне
    if (mounted) {
      precacheImage(
        CachedNetworkImageProvider(imagePath),
        context,
      ).then((_) {
        debugPrint('✅ Precached: ${imagePath.split('/').last}');
      }).catchError((e) {
        // Игнорируем ошибки предзагрузки
        debugPrint('⚠️ Precache failed: ${imagePath.split('/').last}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cardBg, // Зеленоватый оттенок как на профиле
      body: BlocConsumer<NewsBloc, NewsState>(
        listener: (context, state) {
          // Обработка ошибок
          if (state.isFailure && state.error != null) {
            showSnackBar(context, state.error ?? '');

            // Сбрасываем флаг загрузки при ошибке
            if (_isLoadingMore) {
              setState(() {
                _isLoadingMore = false;
                _currentPage--;
              });
            }

            // При ошибке сбрасываем флаг загрузки
          }

          // Обработка успешной загрузки
          if (state.isSuccess) {
            final newsData = state.newsEntity?.data ?? [];

            // Обновляем локальный кэш всех новостей
            if (newsData.isNotEmpty) {
              _updateAllNews(newsData);
            }

            if (_isLoadingMore) {
              setState(() {
                _isLoadingMore = false;
                if (newsData.isEmpty || newsData.length < 10) {
                  _hasMoreData = false;
                }
              });
            }
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
              onRefresh: _handleRefresh,
              displacement: 40.0, // Расстояние от верха
              strokeWidth: 2.0,
              backgroundColor: _cardBg,
              color: Theme.of(context).primaryColor,
              child: _buildContent(state));
        },
      ),
    );
  }

  Widget _buildContent(NewsState state) {
    // Показываем skeleton только при первой загрузке
    if (state.isLoading && _currentPage == 1 && _allNews.isEmpty) {
      return _buildSkeletonContent();
    }
    if (state.isFailure && _currentPage == 1 && _allNews.isEmpty) {
      return _buildScrollableErrorWidget(state.error ?? 'Неизвестная ошибка');
    }

    if ((state.isSuccess || _allNews.isNotEmpty) &&
        state.categoriesList.isNotEmpty) {
      return _buildSuccessContent(state);
    }
    return _buildSkeletonContent();
  }

  Widget _buildSkeletonContent() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: _buildSkeletonHeader(),
        ),
        SliverToBoxAdapter(
          child: _buildSkeletonTabBar(),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _buildSkeletonNewsItem(),
            ),
            childCount: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Skeleton для карусели баннеров
        _buildSkeletonCarousel(),

        SizedBox(height: 27.h),

        // Skeleton для историй
        _buildSkeletonStories(),

        SizedBox(height: 20.h),

        // Skeleton заголовка новостей
        _buildSkeletonNewsHeader(),

        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildSkeletonCarousel() {
    return Container(
      height: 200.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: SkeletonBox(
        width: double.infinity,
        height: 200.h,
        borderRadius: 20.r,
        controller: _shimmerController,
      ),
    );
  }

  Widget _buildSkeletonStories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(width: 16.w),
          ...List.generate(
              3,
              (index) => Row(
                    children: [
                      SkeletonBox(
                        width: 60.w,
                        height: 60.w,
                        borderRadius: 30.w,
                        controller: _shimmerController,
                      ),
                      SizedBox(width: 15.w),
                    ],
                  )),
        ],
      ),
    );
  }

  Widget _buildSkeletonNewsHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SkeletonBox(
        width: 120.w,
        height: 24.h,
        borderRadius: 4.r,
        controller: _shimmerController,
      ),
    );
  }

  Widget _buildSkeletonTabBar() {
    return Container(
      width: double.infinity,
      height: 50.h,
      color: _cardBg,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: List.generate(
            4,
            (index) => Row(
                  children: [
                    SkeletonBox(
                      width: 60.w,
                      height: 20.h,
                      borderRadius: 4.r,
                      controller: _shimmerController,
                    ),
                    SizedBox(width: 20.w),
                  ],
                )),
      ),
    );
  }

  Widget _buildSkeletonNewsItem() {
    return Container(
      margin: EdgeInsets.only(bottom: 40.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton для категории
          SkeletonBox(
            width: 80.w,
            height: 16.h,
            borderRadius: 4.r,
            controller: _shimmerController,
          ),

          SizedBox(height: 8.h),

          // Skeleton для заголовка
          SkeletonBox(
            width: double.infinity,
            height: 20.h,
            borderRadius: 4.r,
            controller: _shimmerController,
          ),

          SizedBox(height: 6.h),

          SkeletonBox(
            width: 250.w,
            height: 20.h,
            borderRadius: 4.r,
            controller: _shimmerController,
          ),

          SizedBox(height: 22.h),

          // Skeleton для изображения
          SkeletonBox(
            width: double.infinity,
            height: 191.h,
            borderRadius: 20.r,
            controller: _shimmerController,
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableErrorWidget(String error) {
    final l10n = AppLocalizations.of(context)!;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                SizedBox(height: 12.h),
                Text(
                  l10n.loadError,
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: _handleRefresh, // ✅ Используем _handleRefresh
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent(NewsState state) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: scrollController,
      slivers: [
        // Header content
        SliverToBoxAdapter(
          child: _buildHeader(state),
        ),

        // Sticky tab bar
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            child: TabBarWidget(
              state: state,
              selectedIndex: selectedIndex,
              onCategorySelected: (index) => _onCategoryChanged(index, state),
            ),
          ),
        ),

        // News list с анимацией
        _buildAnimatedSliverNewsList(state),
        // Индикатор загрузки для пагинации
        if (_isLoadingMore)
          SliverToBoxAdapter(
            child: _buildLoadingMoreIndicator(),
          ),

        // Сообщение о конце списка
        if (!_hasMoreData &&
            state.newsEntity != null &&
            state.newsEntity!.data.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildEndOfListMessage(),
          ),

        // Отступ для NavBar
        SliverToBoxAdapter(
          child: SizedBox(
            height: NavBar.getBottomPadding(context),
          ),
        )
      ],
    );
  }

  Widget _buildLoadingMoreIndicator() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.loadingNews,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndOfListMessage() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30.h),
      child: Center(
        child: Text(
          l10n.viewedAllNews,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // Анимированный Sliver список новостей
  Widget _buildAnimatedSliverNewsList(NewsState state) {
    // Используем локально отфильтрованные данные
    final newsData = _filteredNews.isNotEmpty
        ? _filteredNews
        : (state.newsEntity?.data ?? []);

    if (newsData.isEmpty) {
      return SliverFillRemaining(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildEmptyNewsList(),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final newsItem = newsData[index];
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _buildNewsItem(newsItem, index),
              ),
            ),
          );
        },
        childCount: newsData.length,
      ),
    );
  }

  Widget _buildHeader(NewsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Карусель баннеров
        _buildCarouselSection(state),

        SizedBox(height: 27.h),

        // Секция историй
        _buildStoriesSection(state),

        SizedBox(height: 20.h),

        // Заголовок новостей
        _buildNewsHeader(),

        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildCarouselSection(NewsState state) {
    // Фильтруем баннеры по периодам (start_date, expired_at)
    final visibleBanners = (state.banners?.data ?? [])
        .where((banner) => banner.isVisibleNow)
        .toList();
    
    return Carousel(
      controller: controller,
      bannerList: visibleBanners,
    );
  }

  Widget _buildStoriesSection(NewsState state) {
    // Проверяем наличие актуалов
    if (state.actuals.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(width: 16.w),
          ...List.generate(
            state.actuals.length, // Ограничиваем до 3 элементов
            (index) => Row(
              children: [
                Stories(
                  stories: state.actuals[index].stories,
                  title: state.actuals[index].actualGroup,
                ),
                SizedBox(width: 20.w),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            l10n.news,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNewsList() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.3,
        ),
        padding: EdgeInsets.symmetric(vertical: 60.h, horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 36.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.noNewsFound,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsItem(NewsListEntity newsItem, int index) {
    final hasImage = newsItem.blocks.isNotEmpty &&
        newsItem.blocks[0].mediaPath != null &&
        newsItem.blocks[0].mediaPath!.isNotEmpty;

    // Находим текст из блоков для превью
    final previewText = _getPreviewText(newsItem.blocks);

    return GestureDetector(
      onTap: () => _navigateToNewsDetail(newsItem),
      child: Container(
        margin: EdgeInsets.only(bottom: 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение с соотношением 3:4 и Hero-анимацией
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              child: hasImage
                  ? _buildNewsImage(newsItem.blocks[0].mediaPath!, newsItem.id)
                  : _buildImagePlaceholder(),
            ),
            // Контент под изображением
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Категория как badge
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      newsItem.category.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B5E20),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  // Заголовок
                  Text(
                    newsItem.name,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Превью текста
                  if (previewText.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      previewText,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 12.h),
                  // Кнопка "Подробнее"
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.readMore,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16.sp,
                        color: const Color(0xFF1B5E20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Получаем текст для превью из блоков новости
  String _getPreviewText(List<dynamic> blocks) {
    for (final block in blocks) {
      if (block.text != null && block.text!.isNotEmpty) {
        // Убираем HTML-теги если есть и возвращаем чистый текст
        return block.text!
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }
    }
    return '';
  }

  Widget _buildImagePlaceholder() {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[200]!,
              Colors.grey[100]!,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.article_outlined,
            size: 48.sp,
            color: Colors.grey[350],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsImage(String imagePath, int newsId) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Hero(
        tag: 'news_image_$newsId',
        child: CachedNetworkImage(
          imageUrl: imagePath,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[100],
            child: Center(
              child: SizedBox(
                width: 24.w,
                height: 24.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[100],
            child: Center(
              child:
                  Icon(Icons.broken_image, color: Colors.grey[400], size: 48),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToNewsDetail(NewsListEntity newsItem) {
    try {
      final currentPosition =
          scrollController.hasClients ? scrollController.offset : 0.0;

      // Получаем URL изображения для Hero-анимации
      String? heroImageUrl;
      if (newsItem.blocks.isNotEmpty &&
          newsItem.blocks[0].mediaPath != null &&
          newsItem.blocks[0].mediaPath!.isNotEmpty) {
        final mediaPath = newsItem.blocks[0].mediaPath!;
        // Проверяем что это не видео
        if (!mediaPath.contains('.mp4') && !mediaPath.contains('.mov')) {
          heroImageUrl = mediaPath;
        }
      }

      Navigator.of(context, rootNavigator: true)
          .push(
        // Используем кастомный PageRoute с Hero-анимацией
        NewsDetailPageRoute(
          newsId: newsItem.id,
          newsTitle: newsItem.name,
          heroImageUrl: heroImageUrl,
        ),
      )
          .then((_) {
        // Восстанавливаем позицию скролла при возврате
        if (mounted && scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollController.hasClients) {
              scrollController.jumpTo(currentPosition);
            }
          });
        }
      });
    } catch (e) {
      debugPrint('Ошибка навигации: $e');
      showSnackBar(context, 'Не удалось открыть новость');
    }
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  double get minExtent => 50;
  @override
  double get maxExtent => 50;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F0),
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}




