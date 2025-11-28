import 'dart:async';
import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';
import 'package:ketroy_app/features/news/domain/entities/story_entity.dart';
import 'package:ketroy_app/features/stories/presentation/widgets/animated_bar.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:ketroy_app/select_page.dart';
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';
import 'package:ketroy_app/services/shared_preferences_service.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:video_player/video_player.dart';

class StoriesScreen extends StatefulWidget {
  final bool firstLaunch;
  final List<StoryEntity> stories;

  const StoriesScreen({
    super.key,
    required this.stories,
    required this.firstLaunch,
  });

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen>
    with SingleTickerProviderStateMixin {
  PageController? _pageController;
  AnimationController? _animationController;
  VideoPlayerController? _videoController;
  Timer? _videoLoadingTimer; // Таймер для fallback загрузки видео
  bool _isMuted = false;

  int currentIndex = 0;
  bool _isDisposed = false;
  bool _isNavigating = false; // Предотвращает множественную навигацию
  bool _isContentLoaded = false;

  // Для свайпа вниз (закрытие как в Instagram)
  double _dragOffset = 0.0;
  bool _isDragging = false;

  // Для предзагрузки изображений
  final Map<int, bool> _preloadedImages = {};
  bool _didInitializePreload = false;
  
  // Предзагрузка следующего видео (только ОДНО видео вперёд!)
  VideoPlayerController? _nextVideoController;
  int? _nextVideoIndex;
  bool _isPreloadingNextVideo = false;
  
  // Для синхронизации видео
  Timer? _videoSyncTimer;
  bool _isBuffering = false;
  bool _isVideoLoading = false; // Флаг загрузки видео

  final sharedService = serviceLocator<SharedPreferencesService>();

  // Проверка поддержки видео на текущей платформе
  bool get _isVideoSupportedOnPlatform {
    if (kIsWeb) return true; // Web поддерживает через HTML5
    try {
      return !Platform.isWindows &&
          !Platform.isLinux; // Windows и Linux пока не поддерживают
    } catch (e) {
      return false; // Fallback для неизвестных платформ
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.stories.isNotEmpty) {
      _initializeControllers();
    }
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // прозрачный фон
        statusBarIconBrightness: Brightness.light, // Android
        statusBarBrightness: Brightness.dark, // iOS: белые иконки
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Предзагружаем контент после того, как MediaQuery станет доступен
    if (!_didInitializePreload && widget.stories.isNotEmpty) {
      _didInitializePreload = true;
      _preloadContent();
      _loadStory(story: widget.stories.first, animateToPage: false);
    }
  }

  void _initializeControllers() {
    if (_isDisposed) return;

    _pageController = PageController();
    _animationController = AnimationController(vsync: this);

    _animationController?.addStatusListener(_onAnimationStatusChanged);
  }

  // Метод для предзагрузки контента
  void _preloadContent() {
    // Предзагружаем изображения для следующих 2 сторис
    final int endIndex = (currentIndex + 2).clamp(0, widget.stories.length - 1);

    for (int i = currentIndex; i <= endIndex; i++) {
      final story = widget.stories[i];

      if (story.type == 'image' && !_preloadedImages.containsKey(i)) {
        _preloadImage(i, story, useCover: false);
      }
    }
    
    // ❌ ОТКЛЮЧЕНО: Предзагрузка создаёт конфликт аудио ресурсов
    // _preloadNextVideo();
  }
  
  /// Предзагрузка следующего видео в фоне
  /// ❌ ОТКЛЮЧЕНО: Создаёт конфликт аудио ресурсов на Android
  // ignore: unused_element
  void _preloadNextVideo() {
    if (_isDisposed || !_isVideoSupportedOnPlatform || _isPreloadingNextVideo) return;
    
    // Если уже есть готовое предзагруженное видео — не трогаем его!
    if (_nextVideoController != null && _nextVideoController!.value.isInitialized) {
      return;
    }
    
    // Ищем следующее видео после текущего индекса
    int? nextVideoIdx;
    for (int i = currentIndex + 1; i < widget.stories.length; i++) {
      if (widget.stories[i].type == 'video') {
        nextVideoIdx = i;
        break;
      }
    }
    
    // Также проверяем, может текущая история — видео и нужно его предзагрузить
    if (nextVideoIdx == null && widget.stories[currentIndex].type == 'video') {
      nextVideoIdx = currentIndex;
    }
    
    // Если видео нет или уже предзагружено — выходим
    if (nextVideoIdx == null || nextVideoIdx == _nextVideoIndex) return;
    
    _isPreloadingNextVideo = true;
    _nextVideoIndex = nextVideoIdx;
    final story = widget.stories[nextVideoIdx];
    
    debugPrint('🔄 Предзагружаем видео для индекса $nextVideoIdx');
    
    try {
      _nextVideoController = VideoPlayerController.networkUrl(
        Uri.parse(story.filePath),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      
      // Только инициализируем — НЕ запускаем воспроизведение!
      // Это позволит ExoPlayer скачать метаданные и подготовиться
      _nextVideoController!.initialize().then((_) {
        _isPreloadingNextVideo = false;
        if (_isDisposed || _nextVideoController == null) return;
        
        // Устанавливаем громкость 0 на всякий случай
        _nextVideoController!.setVolume(0);
        
        debugPrint('✅ Видео инициализировано для индекса $_nextVideoIndex');
      }).catchError((error) {
        _isPreloadingNextVideo = false;
        debugPrint('⚠️ Ошибка предзагрузки видео: $error');
        _disposeNextVideoController();
      });
    } catch (e) {
      _isPreloadingNextVideo = false;
      debugPrint('⚠️ Ошибка создания предзагружаемого контроллера: $e');
    }
  }
  
  /// Очистка предзагруженного видеоконтроллера
  Future<void> _disposeNextVideoController() async {
    if (_nextVideoController != null) {
      final controller = _nextVideoController;
      _nextVideoController = null;
      _nextVideoIndex = null;
      await controller!.dispose();
    }
  }

  void _preloadImage(int index, StoryEntity story, {bool useCover = false}) {
    if (_isDisposed) return;

    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed && mounted) {
          _preloadImage(index, story, useCover: useCover);
        }
      });
      return;
    }

    final imageUrl = useCover ? (story.coverPath ?? story.filePath) : story.filePath;

    precacheImage(
      CachedNetworkImageProvider(imageUrl),
      context,
    ).then((_) {
      if (!_isDisposed && mounted) {
        _preloadedImages[index] = true;
      }
    }).catchError((error) {
      if (!_isDisposed && mounted) {
        _preloadedImages[index] = false;
      }
      return null;
    });
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (_isDisposed || _isNavigating) return;

    if (status == AnimationStatus.completed) {
      _handleStoryCompletion();
    }
  }

  void _handleStoryCompletion() async {
    if (_isDisposed || _isNavigating || _isVideoLoading) return;

    await _cleanupCurrentStory();
    if (_isDisposed) return;

    if (currentIndex + 1 < widget.stories.length) {
      setState(() {
        currentIndex += 1;
      });
      
      _preloadContent();
      _loadStory(story: widget.stories[currentIndex]);
    } else {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    if (_isDisposed || _isNavigating) return;

    _isNavigating = true;

    // Очищаем все ресурсы перед навигацией
    _disposeAllControllers();

    if (widget.firstLaunch) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FutureBuilder<bool>(
            future: UserDataManager.isUserLoggedIn(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Loader(); // Брендовый лоадер
              }

              final isLoggedIn = snapshot.data ?? false;
              return isLoggedIn
                  ? NavScreen(
                      key: NavScreen.globalKey,
                      initialTab: 0,
                    )
                  : SelectPage();
            },
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  /// Очистка текущей истории (асинхронная для видео)
  Future<void> _cleanupCurrentStory() async {
    _isContentLoaded = false;
    _isBuffering = false;
    _isVideoLoading = false;

    // Отменяем таймеры
    _videoLoadingTimer?.cancel();
    _videoLoadingTimer = null;
    _videoSyncTimer?.cancel();
    _videoSyncTimer = null;

    _animationController?.stop();
    _animationController?.reset();

    // Очищаем видео контроллер и ждём освобождения ресурсов
    await _safeDisposeVideoController();
  }

  /// Безопасная очистка видео контроллера с ожиданием
  Future<void> _safeDisposeVideoController() async {
    if (_videoController != null) {
      final controller = _videoController;
      _videoController = null;
      
      try {
        controller!.removeListener(_videoListener);
        await controller.pause();
        await controller.dispose();
        debugPrint('🗑️ Видео контроллер очищен');
      } catch (e) {
        debugPrint('⚠️ Ошибка при очистке видео контроллера: $e');
      }
      
      // Даём время MediaCodec освободить ресурсы
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  Future<void> _disposeAllControllers() async {
    // Очищаем таймеры
    _videoLoadingTimer?.cancel();
    _videoLoadingTimer = null;
    _videoSyncTimer?.cancel();
    _videoSyncTimer = null;

    // Очищаем текущий видео контроллер
    if (_videoController != null) {
      try {
        _videoController!.removeListener(_videoListener);
        _videoController!.pause();
        await _videoController!.dispose();
      } catch (e) {
        debugPrint('⚠️ Ошибка при dispose контроллера: $e');
      }
      _videoController = null;
    }
    
    // Очищаем предзагруженный видео контроллер
    await _disposeNextVideoController();

    _preloadedImages.clear();

    if (_animationController != null && !_animationController!.isDismissed) {
      _animationController!.removeStatusListener(_onAnimationStatusChanged);
      _animationController!.dispose();
      _animationController = null;
    }

    _pageController?.dispose();
    _pageController = null;
  }

  // Метод для переключения звука
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeAllControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final aspectRatio = screenWidth / 700.h;
    if (_isDisposed || widget.stories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white, // ✅ Белый фон при загрузке
        body: Loader(),
      );
    }

    final StoryEntity story = widget.stories[currentIndex];

    // Расчёт прозрачности для свайпа вниз (без изменения размера!)
    final double dragProgress = (_dragOffset / 300).clamp(0.0, 1.0);
    final double opacity = 1.0 - (dragProgress * 0.5); // Затухает до 0.5

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Stack(
          children: [
            // Чёрный фон всегда сзади
            Container(color: Colors.black),

            // Контент сторис — просто смещается вниз без изменения размера
            Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: SafeArea(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTapDown: (details) => _onTapDown(details, story),
                        child: SizedBox(
                          width: screenWidth,
                          height: screenWidth / aspectRatio,
                          child: Stack(
                            children: [
                              _buildStoryContent(),
                              _buildProgressBar(),
                              _buildTopRightButtons(),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: Colors.black,
                          child: Center(
                            child: Image.asset('images/ketroy-word.png'),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Обработчики свайпа вниз
  void _onVerticalDragStart(DragStartDetails details) {
    _isDragging = true;
    // Приостанавливаем анимацию при начале свайпа
    if (_animationController?.isAnimating == true) {
      _animationController?.stop();
    }
    if (_videoController?.value.isPlaying == true) {
      _videoController?.pause();
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    setState(() {
      // Только свайп вниз (положительные значения)
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, 400.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0;

    // Закрываем если свайпнули достаточно далеко или быстро
    if (_dragOffset > 150 || velocity > 500) {
      // Анимируем закрытие
      _animateClose();
    } else {
      // Возвращаем обратно
      _animateReturn();
    }
  }

  void _animateClose() {
    // Быстрая анимация закрытия
    const duration = Duration(milliseconds: 200);
    final startOffset = _dragOffset;
    final endOffset = MediaQuery.of(context).size.height;

    // Используем простую анимацию через setState
    int steps = 10;
    double step = (endOffset - startOffset) / steps;

    void animateStep(int currentStep) {
      if (_isDisposed || currentStep >= steps) {
        _navigateToNextScreen();
        return;
      }

      Future.delayed(Duration(milliseconds: duration.inMilliseconds ~/ steps),
          () {
        if (!_isDisposed && mounted) {
          setState(() {
            _dragOffset = startOffset + (step * (currentStep + 1));
          });
          animateStep(currentStep + 1);
        }
      });
    }

    animateStep(0);
  }

  void _animateReturn() {
    // Плавно возвращаем на место
    const duration = Duration(milliseconds: 200);
    final startOffset = _dragOffset;

    int steps = 10;
    double step = startOffset / steps;

    void animateStep(int currentStep) {
      if (_isDisposed || currentStep >= steps) {
        // Возобновляем воспроизведение
        if (_animationController != null && _isContentLoaded) {
          _animationController!.forward();
        }
        if (_videoController != null) {
          _videoController!.play();
        }
        return;
      }

      Future.delayed(Duration(milliseconds: duration.inMilliseconds ~/ steps),
          () {
        if (!_isDisposed && mounted) {
          setState(() {
            _dragOffset = startOffset - (step * (currentStep + 1));
          });
          animateStep(currentStep + 1);
        }
      });
    }

    animateStep(0);
  }

  Widget _buildTopRightButtons() {
    return Positioned(
      top: 30.h,
      right: 14.w,
      child: Row(
        children: [
          // Кнопка звука
          GestureDetector(
            onTap: _toggleMute,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Icon(
                _isMuted 
                    ? CupertinoIcons.speaker_slash
                    : CupertinoIcons.speaker_2,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // Кнопка закрытия
          GestureDetector(
            onTap: _navigateToNextScreen,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Icon(
                CupertinoIcons.xmark,
                color: Colors.white,
                size: 22.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    // Защита от null контроллера
    if (_animationController == null) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      top: 10.0,
      left: 10.0,
      right: 10.0,
      child: Row(
        children: widget.stories
            .asMap()
            .map((i, e) {
              return MapEntry(
                i,
                AnimatedBar(
                  animController: _animationController!,
                  position: i,
                  currentIndex: currentIndex,
                  isContentLoaded: _isContentLoaded,
                ),
              );
            })
            .values
            .toList(),
      ),
    );
  }

  Widget _buildStoryContent() {
    if (_pageController == null) {
      return const Loader();
    }

    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.stories.length,
      itemBuilder: (context, i) {
        final StoryEntity story = widget.stories[i];
        return _buildStoryItem(story, i);
      },
    );
  }

  void _onTapDown(TapDownDetails details, StoryEntity story) {
    if (_isDisposed || _isNavigating || !_isContentLoaded) return;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double dx = details.globalPosition.dx;

    if (dx < screenWidth / 3) {
      _goToPreviousStory();
    } else if (dx > 2 * screenWidth / 3) {
      _goToNextStory();
    } else {
      _togglePlayPause(story);
    }
  }

  void _goToNextStory() async {
    if (_isDisposed || _isNavigating || _isVideoLoading) return;

    if (currentIndex + 1 < widget.stories.length) {
      await _cleanupCurrentStory();
      if (_isDisposed) return;
      
      setState(() {
        currentIndex += 1;
      });
      
      _preloadContent();
      _loadStory(story: widget.stories[currentIndex]);
    } else {
      _navigateToNextScreen();
    }
  }

  void _goToPreviousStory() async {
    if (_isDisposed || _isNavigating || currentIndex <= 0 || _isVideoLoading) return;

    await _cleanupCurrentStory();
    if (_isDisposed) return;
    
    setState(() {
      currentIndex -= 1;
    });
    
    _loadStory(story: widget.stories[currentIndex]);
  }

  void _togglePlayPause(StoryEntity story) {
    if (_isDisposed || _animationController == null || !_isContentLoaded) {
      return;
    }

    if (story.type == 'video' && _videoController != null) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _animationController!.stop();
      } else {
        _videoController!.play();
        _animationController!.forward();
      }
    } else {
      if (_animationController!.isAnimating) {
        _animationController!.stop();
      } else {
        _animationController!.forward();
      }
    }
  }

  /// Загрузка истории (асинхронная для правильной очистки ресурсов)
  Future<void> _loadStory({required StoryEntity story, bool animateToPage = true}) async {
    if (_isDisposed || _animationController == null) return;

    _animationController!.stop();
    _animationController!.reset();
    _isContentLoaded = false;

    // ✅ ВАЖНО: Сначала полностью очищаем предыдущий контроллер и ждём
    await _safeDisposeVideoController();

    if (_isDisposed) return; // Проверяем после await

    switch (story.type) {
      case 'image':
        _loadImageStory();
        break;
      case 'video':
        if (_isVideoSupportedOnPlatform) {
          _loadVideoStory(story);
        } else {
          // На неподдерживаемых платформах переходим к следующей истории
          debugPrint('⚠️ Видео не поддерживается на этой платформе');
          _goToNextStory();
        }
        break;
      default:
        _loadImageStory();
        break;
    }

    if (animateToPage && _pageController != null && !_isDisposed) {
      _pageController!.animateToPage(
        currentIndex,
        duration: const Duration(milliseconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }

  // Метод для запуска анимации после загрузки контента
  void _startAnimationAfterContentLoaded() {
    if (_isDisposed || _animationController == null) return;

    setState(() {
      _isContentLoaded = true; // Устанавливаем флаг загрузки
    });

    // Небольшая задержка для плавности
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_isDisposed && _animationController != null && mounted) {
        _animationController!.forward();
      }
    });
  }

  void _loadImageStory() {
    if (_isDisposed || _animationController == null) return;

    _animationController!.duration = const Duration(seconds: 5);

    // ❌ ОТКЛЮЧЕНО: Предзагрузка создаёт конфликт аудио ресурсов
    // _preloadNextVideo();
  }

  // Коллбек для уведомления о загрузке изображения
  void _onImageLoaded() {
    if (!_isDisposed && mounted && !_isContentLoaded) {
      _startAnimationAfterContentLoaded();
    }
  }

  void _loadVideoStory(StoryEntity story) async {
    if (_isDisposed || _isVideoLoading) return;
    
    _isVideoLoading = true;

    // Проверяем, есть ли предзагруженное видео для этого индекса
    if (_nextVideoController != null && _nextVideoIndex == currentIndex) {
      if (_nextVideoController!.value.isInitialized) {
        debugPrint('⚡ Используем предзагруженное видео для индекса $currentIndex');
        
        // Сначала dispose старый контроллер и ЖДЁМ освобождения ресурсов!
        if (_videoController != null) {
          debugPrint('🗑️ Disposing старого контроллера...');
          _videoController!.removeListener(_videoListener);
          await _videoController!.dispose();
          _videoController = null;
          // Даём Android время освободить аудио декодер
          await Future.delayed(const Duration(milliseconds: 150));
          debugPrint('✅ Старый контроллер очищен');
        }
        
        if (_isDisposed) return;
        
        // Используем предзагруженный контроллер
        _videoController = _nextVideoController;
        _nextVideoController = null;
        _nextVideoIndex = null;
        _isVideoLoading = false;
        
        _setupVideoPlayback();
        return;
      } else {
        // Ждем инициализации предзагруженного видео
        debugPrint('⏳ Ждем инициализации предзагруженного видео для индекса $currentIndex');
        _waitForPreloadedVideo();
        return;
      }
    }
    
    debugPrint('📥 Загружаем видео для индекса $currentIndex (предзагрузка: idx=$_nextVideoIndex, ctrl=${_nextVideoController != null})');

    try {
      // Очищаем предзагруженное видео если оно для другого индекса
      await _disposeNextVideoController();
      
      // Dispose старый контроллер и ЖДЁМ освобождения ресурсов!
      if (_videoController != null) {
        debugPrint('🗑️ Disposing старого контроллера...');
        _videoController!.removeListener(_videoListener);
        await _videoController!.dispose();
        _videoController = null;
        // Даём Android время освободить аудио декодер
        await Future.delayed(const Duration(milliseconds: 150));
        debugPrint('✅ Старый контроллер очищен');
      }
      
      if (_isDisposed) return;
      
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(story.filePath),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      _videoController!.initialize().then((_) {
        _isVideoLoading = false;
        
        if (_isDisposed || !mounted || _videoController == null || _animationController == null) {
          return;
        }
        
        debugPrint('✅ Видео инициализировано для индекса $currentIndex');
        _setupVideoPlayback();
      }).catchError((error) {
        _isVideoLoading = false;
        debugPrint('⚠️ Ошибка инициализации видео: $error');
        
        if (!_isDisposed && mounted) {
          _safeDisposeVideoController();
          _goToNextStory();
        }
      });
    } catch (error) {
      _isVideoLoading = false;
      debugPrint('⚠️ Ошибка создания VideoController: $error');
      
      if (!_isDisposed && mounted) {
        _safeDisposeVideoController();
        _goToNextStory();
      }
    }
  }
  
  /// Ожидание инициализации предзагруженного видео
  void _waitForPreloadedVideo() {
    if (_isDisposed) return;
    
    int checkCount = 0;
    const maxChecks = 60; // 3 секунды (60 * 50мс)
    
    void checkPreloaded() async {
      if (_isDisposed || _nextVideoController == null) {
        _isVideoLoading = false;
        return;
      }
      
      checkCount++;
      
      if (_nextVideoController!.value.isInitialized && _nextVideoIndex == currentIndex) {
        debugPrint('⚡ Предзагруженное видео готово для индекса $currentIndex');
        
        // Dispose старый контроллер и ЖДЁМ освобождения ресурсов!
        if (_videoController != null) {
          debugPrint('🗑️ Disposing старого контроллера...');
          _videoController!.removeListener(_videoListener);
          await _videoController!.dispose();
          _videoController = null;
          // Даём Android время освободить аудио декодер
          await Future.delayed(const Duration(milliseconds: 150));
          debugPrint('✅ Старый контроллер очищен');
        }
        
        if (_isDisposed) return;
        
        _videoController = _nextVideoController;
        _nextVideoController = null;
        _nextVideoIndex = null;
        _isVideoLoading = false;
        _setupVideoPlayback();
      } else if (_nextVideoIndex != currentIndex) {
        // Индекс изменился, загружаем заново
        _isVideoLoading = false;
        _loadVideoStory(widget.stories[currentIndex]);
      } else if (checkCount >= maxChecks) {
        // Таймаут — загружаем сами
        debugPrint('⏱️ Таймаут ожидания предзагрузки — загружаем заново');
        await _disposeNextVideoController();
        _isVideoLoading = false;
        _loadVideoStory(widget.stories[currentIndex]);
      } else {
        // Еще не готово — проверяем через 50мс
        Future.delayed(const Duration(milliseconds: 50), checkPreloaded);
      }
    }
    
    checkPreloaded();
  }

  /// Настройка воспроизведения видео после инициализации
  void _setupVideoPlayback() {
    if (_isDisposed || _videoController == null || _animationController == null) return;

    setState(() {});

    if (_videoController!.value.isInitialized) {
      final duration = _videoController!.value.duration;
      _animationController!.duration = duration;
      
      // НЕ устанавливаем громкость здесь — делаем это в _startPlayback
      // когда аудио декодер точно готов!
      
      // Добавляем улучшенный слушатель
      _videoController!.addListener(_videoListener);

      // ✅ ОПТИМИЗАЦИЯ: Ждём буферизации (включая аудио!) перед воспроизведением
      _waitForBufferingAndPlay();
    }
  }

  /// Запуск воспроизведения — ПРОСТОЙ подход без хитростей
  void _waitForBufferingAndPlay() {
    if (_isDisposed || _videoController == null) return;

    // Сразу устанавливаем громкость и запускаем
    _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
    _videoController!.play();
    
    debugPrint('▶️ Воспроизведение запущено напрямую');
    
    // Запускаем анимацию и таймер синхронизации
    _startAnimationAfterContentLoaded();
    _startVideoSyncTimer();
  }


  /// Таймер для синхронизации анимации с позицией видео
  void _startVideoSyncTimer() {
    _videoSyncTimer?.cancel();
    _videoSyncTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_isDisposed || _videoController == null || _animationController == null) {
        timer.cancel();
        return;
      }

      final value = _videoController!.value;
      
      // Обрабатываем буферизацию — только останавливаем АНИМАЦИЮ
      // НЕ трогаем видео! ExoPlayer сам управляет буферизацией
      if (value.isBuffering && !_isBuffering) {
        _isBuffering = true;
        _animationController!.stop();
        if (mounted) setState(() {});
      } else if (!value.isBuffering && _isBuffering) {
        _isBuffering = false;
        _animationController!.forward();
        if (mounted) setState(() {});
      }

      // Синхронизируем позицию анимации с видео
      if (value.isPlaying && !value.isBuffering && value.duration.inMilliseconds > 0) {
        final videoProgress = value.position.inMilliseconds / value.duration.inMilliseconds;
        final animProgress = _animationController!.value;
        
        // Корректируем если рассинхронизация больше 3%
        if ((videoProgress - animProgress).abs() > 0.03) {
          _animationController!.value = videoProgress.clamp(0.0, 1.0);
        }
      }
    });
  }

  // Слушатель для отслеживания состояния видео (обработка ошибок и завершения)
  void _videoListener() {
    if (_isDisposed || _videoController == null) return;

    final value = _videoController!.value;

    // Обрабатываем ошибки воспроизведения
    if (value.hasError) {
      debugPrint('❌ Ошибка видео: ${value.errorDescription}');
      _videoSyncTimer?.cancel();
      // Переходим к следующей истории
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_isDisposed && mounted) {
          _goToNextStory();
        }
      });
      return;
    }

    // Обрабатываем завершение видео
    if (value.isInitialized && 
        value.position >= value.duration - const Duration(milliseconds: 200) &&
        value.duration.inMilliseconds > 0) {
      // Видео закончилось — убираем слушатель чтобы не дублировать
      _videoController!.removeListener(_videoListener);
    }
  }

  Widget _buildStoryItem(StoryEntity story, int storyIndex) {
    switch (story.type) {
      case 'image':
        return CachedNetworkImage(
          imageUrl: story.filePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (context, url, error) => const Center(
            child: Icon(Icons.error, color: Colors.white, size: 50),
          ),
          imageBuilder: (context, imageProvider) {
            // Проверяем, что это текущая история
            if (storyIndex == currentIndex) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onImageLoaded();
              });
            }
            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        );

      case 'video':
        // Показываем видео только для текущего индекса когда готово
        if (storyIndex == currentIndex && _videoController != null && _videoController!.value.isInitialized) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Видео на весь экран
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              ),
              // Индикатор буферизации поверх видео
              if (_isBuffering)
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
            ],
          );
        }
        
        // Пока видео загружается — черный экран с индикатором (без изображений!)
        return Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );

      default:
        return const Center(
          child: Text(
            'Неподдерживаемый тип контента',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }
}
