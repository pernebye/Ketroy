import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final VideoPlayerController controller;
  final String videoPath;
  final String? resolution;

  const VideoPlayerWidget(
      {super.key,
      required this.controller,
      required this.videoPath,
      this.resolution});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isInitializing = false;
  String? _errorMessage;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (_isInitializing) return; // Предотвращаем множественную инициализацию

    setState(() {
      _isInitializing = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      debugPrint('Initializing video: ${widget.videoPath}');

      // ✅ ВАЖНО: Проверяем что контроллер еще не инициализирован
      if (widget.controller.value.isInitialized) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isInitializing = false;
          });
          widget.controller.addListener(_videoListener);
        }
        return;
      }

      // ✅ Добавляем таймаут для инициализации
      await widget.controller.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Время ожидания загрузки видео истекло');
        },
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isInitializing = false;
        });

        // ✅ Добавляем слушатель только после успешной инициализации
        widget.controller.addListener(_videoListener);

        debugPrint('Video initialized successfully');
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitializing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || !_isInitialized) return;

    final isPlaying = widget.controller.value.isPlaying;
    final hasError = widget.controller.value.hasError;

    if (hasError && !_hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = widget.controller.value.errorDescription ??
            'Ошибка воспроизведения видео';
      });
      return;
    }

    if (_isPlaying != isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
      });
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      widget.controller.removeListener(_videoListener);
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;

    try {
      if (_isPlaying) {
        widget.controller.pause();
      } else {
        widget.controller.play();
      }
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    // ✅ Автоматически скрываем контролы через 3 секунды
    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls && _isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _toggleFullscreen() {
    if (_isFullscreen) {
      _exitFullscreen();
    } else {
      _enterFullscreen();
    }
  }

  void _enterFullscreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => FullscreenVideoPlayer(
          controller: widget.controller,
          onExitFullscreen: _exitFullscreen,
        ),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
              child: child,
            ),
          );
        },
      ),
    );

    setState(() {
      _isFullscreen = true;
    });
  }

  void _exitFullscreen() {
    if (_isFullscreen) {
      Navigator.of(context).pop();
      setState(() {
        _isFullscreen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(21.r),
      child: Container(
        height: 200.h,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            // ✅ Видеоплеер с правильным AspectRatio
            Center(
              child: AspectRatio(
                aspectRatio: widget.resolution == 'portrait'
                    ? 9 / 16
                    : 16 / 9, // Fallback aspect ratio
                child: VideoPlayer(widget.controller),
              ),
            ),

            // ✅ Прозрачная область для управления контролами
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleControls,
                behavior: HitTestBehavior.translucent,
              ),
            ),

            // Оверлей с контролами
            if (_showControls) _buildControlsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.3),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ✅ Улучшенная кнопка play/pause
            Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32.sp,
                  ),
                ),
              ),
            ),

            // ✅ Прогресс-бар с улучшенным дизайном
            Positioned(
              bottom: 20.h,
              left: 15.w,
              right: 15.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: VideoProgressIndicator(
                  widget.controller,
                  allowScrubbing: true,
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  colors: const VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.white54,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
            ),

            // Время воспроизведения (слева)
            Positioned(
              bottom: 50.h,
              left: 15.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _formatDuration(widget.controller.value.position),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Общее время (справа)
            Positioned(
              bottom: 50.h,
              right: 15.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _formatDuration(widget.controller.value.duration),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // ✅ Кнопка полного экрана (опционально)
            Positioned(
              top: 15.h,
              right: 15.w,
              child: GestureDetector(
                onTap: _toggleFullscreen,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(21.r),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            SizedBox(height: 16.h),
            Text(
              'Загрузка видео...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'Подготовка к воспроизведению',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(21.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_disabled,
                  size: 32.sp,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Не удалось загрузить видео',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 8.h),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.sp,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isInitialized = false;
                    _isInitializing = false;
                    _errorMessage = null;
                  });
                  _initializeVideo();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Повторить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '00:00';

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class FullscreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onExitFullscreen;

  const FullscreenVideoPlayer({
    super.key,
    required this.controller,
    required this.onExitFullscreen,
  });

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer>
    with TickerProviderStateMixin {
  bool _showControls = true;
  bool _isPlaying = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ СНАЧАЛА устанавливаем полноэкранный режим и принудительную горизонтальную ориентацию
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setFullscreenMode();
    });

    // Инициализируем анимации
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();

    // Слушаем изменения видео
    widget.controller.addListener(_videoListener);
    _isPlaying = widget.controller.value.isPlaying;

    // Автоматически скрываем контролы
    _startControlsTimer();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_videoListener);
    _fadeController.dispose();
    _exitFullscreenMode();
    super.dispose();
  }

  // ✅ Устанавливаем полноэкранный режим БЕЗ принудительного поворота экрана
  void _setFullscreenMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // НЕ принуждаем к повороту - позволяем пользователю самому повернуть устройство
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // ✅ Выходим из полноэкранного режима с восстановлением всех ориентаций
  void _exitFullscreenMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Восстанавливаем все ориентации с приоритетом на портретную
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _videoListener() {
    if (!mounted) return;

    final isPlaying = widget.controller.value.isPlaying;
    if (_isPlaying != isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
      });
    }
  }

  void _togglePlayPause() {
    try {
      if (_isPlaying) {
        widget.controller.pause();
      } else {
        widget.controller.play();
      }
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _startControlsTimer();
    }
  }

  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _showControls && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PopScope(
        onPopInvokedWithResult: (didPop, _) {
          widget.onExitFullscreen();
          if (!didPop) {
            Navigator.of(context).maybePop();
          }
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              // ✅ Полноэкранное видео с адаптивным размером
              Positioned.fill(
                child: OrientationBuilder(
                  builder: (context, orientation) {
                    return Center(
                      child: AspectRatio(
                        aspectRatio: widget.controller.value.aspectRatio > 0
                            ? widget.controller.value.aspectRatio
                            : (orientation == Orientation.landscape
                                ? 16 / 9
                                : 9 / 16),
                        child: VideoPlayer(widget.controller),
                      ),
                    );
                  },
                ),
              ),

              // ✅ Область для жестов
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleControls,
                  onDoubleTap: () {
                    _togglePlayPause();
                    _startControlsTimer();
                  },
                  behavior: HitTestBehavior.translucent,
                ),
              ),

              // ✅ Контролы полноэкранного плеера
              if (_showControls) _buildFullscreenControls(),

              // ✅ Индикатор буферизации
              if (widget.controller.value.isBuffering)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Буферизация...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenControls() {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        return AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Stack(
              children: [
                // ✅ Верхняя панель с кнопкой выхода (адаптируется под ориентацию)
                Positioned(
                  top: isLandscape ? 20 : 50,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      // Кнопка выхода из полноэкранного режима
                      GestureDetector(
                        onTap: widget.onExitFullscreen,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.fullscreen_exit,
                            color: Colors.white,
                            size: isLandscape ? 24.sp : 20.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ✅ Центральная кнопка play/pause
                Center(
                  child: GestureDetector(
                    onTap: () {
                      _togglePlayPause();
                      _startControlsTimer();
                    },
                    child: Container(
                      padding: EdgeInsets.all(isLandscape ? 20 : 18),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: isLandscape ? 48.sp : 40.sp,
                      ),
                    ),
                  ),
                ),

                // ✅ Нижняя панель с прогресс-баром (адаптируется под ориентацию)
                Positioned(
                  bottom: isLandscape ? 20 : 40,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      // Прогресс-бар
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: VideoProgressIndicator(
                          widget.controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          colors: const VideoProgressColors(
                            playedColor: Colors.red,
                            bufferedColor: Colors.white54,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                      SizedBox(height: isLandscape ? 12 : 16),
                      // Время
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _formatDuration(widget.controller.value.position),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isLandscape ? 14.sp : 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _formatDuration(widget.controller.value.duration),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isLandscape ? 14.sp : 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
      },
    );
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '00:00';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
