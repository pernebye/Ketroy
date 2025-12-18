import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ketroy_app/features/ai/presentation/bloc/ai_bloc.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:ketroy_app/services/localization/localization_service.dart';

/// Показать сканер этикеток как нижнюю шторку
Future<bool?> showLabelScannerSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true, // Открываем поверх навбара
    builder: (context) => const LabelScannerSheet(),
  );
}

class LabelScannerSheet extends StatefulWidget {
  const LabelScannerSheet({super.key});

  @override
  State<LabelScannerSheet> createState() => _LabelScannerSheetState();
}

class _LabelScannerSheetState extends State<LabelScannerSheet>
    with SingleTickerProviderStateMixin {
  // Цвета AI темы
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _darkBg = Color(0xFF1A1F12);

  CameraController? controller;
  List<CameraDescription>? cameras;
  bool isInitialized = false;
  bool flashOn = false;
  bool isLoading = false;
  bool _isClosing = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _initializeCamera();
  }

  @override
  void dispose() {
    _pulseController.stop();
    _pulseController.dispose();
    // Dispose камеры в microtask чтобы не блокировать UI
    final cam = controller;
    controller = null;
    if (cam != null) {
      Future.microtask(() async {
        try {
          await cam.dispose();
        } catch (e) {
          debugPrint('Camera dispose error (ignored): $e');
        }
      });
    }
    super.dispose();
  }

  /// Быстрая очистка без ожидания - камера освободится в dispose()
  void _quickCleanup() {
    _pulseController.stop();
  }

  void _closeSheet() {
    if (_isClosing) return;
    _isClosing = true;

    _quickCleanup();

    // Сначала скрываем камеру через setState, затем закрываем sheet
    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras!.isNotEmpty) {
        controller = CameraController(
          cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.bgra8888,
        );

        await controller!.initialize();
        if (mounted) {
          setState(() => isInitialized = true);
        }
      }
    } catch (e) {
      debugPrint('Ошибка инициализации камеры: $e');
    }
  }

  Future<void> _takePicture() async {
    if (controller == null || !controller!.value.isInitialized) return;

    HapticFeedback.mediumImpact();

    try {
      final XFile photo = await controller!.takePicture();
      _showPhotoPreview(photo);
    } catch (e) {
      debugPrint('Error taking photo: $e');
      final l10n = AppLocalizations.of(context)!;
      _showSnackBar(l10n.photoError, isError: true);
    }
  }

  void _showPhotoPreview(XFile photo) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => _PhotoPreviewDialog(
        photoPath: photo.path,
        onConfirm: () async {
          Navigator.of(context).pop();
          await _uploadPhoto(photo);
        },
        onRetake: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _uploadPhoto(XFile photo) async {
    setState(() => isLoading = true);

    try {
      final file = File(photo.path);
      // Получаем правильный код языка для AI напрямую из LocalizationService singleton
      final locService = serviceLocator<LocalizationService>();
      final languageCode = locService.getLanguageCodeForAI();
      final l10n = AppLocalizations.of(context)!;
      
      debugPrint('📤 LabelScannerSheet: Uploading photo with language: $languageCode');
      
      context.read<AiBloc>().add(
        SendImageToServerFetch(
          imageFile: file, 
          languageCode: languageCode,
          userMessage: l10n.analyzeThisLabel,
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      final l10n = AppLocalizations.of(context)!;
      _showSnackBar(l10n.photoLoadError, isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (controller != null) {
      try {
        await controller!.setFlashMode(
          flashOn ? FlashMode.off : FlashMode.torch,
        );
        setState(() => flashOn = !flashOn);
        HapticFeedback.lightImpact();
      } catch (e) {
        debugPrint('Ошибка переключения вспышки: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final l10n = AppLocalizations.of(context)!;

    // Убрали PopScope - пусть sheet закрывается свободно,
    // камера освободится в dispose()
    return BlocListener<AiBloc, AiState>(
      listener: (context, state) {
        if (state.isSuccess) {
          Navigator.pop(context, true);
          _showSnackBar(l10n.imageSentForAnalysis);
        } else if (state.isFailure) {
          setState(() => isLoading = false);
          _showSnackBar(state.message ?? l10n.sendError, isError: true);
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: _darkBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28.r),
            topRight: Radius.circular(28.r),
          ),
        ),
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(),
            Expanded(child: _buildCamera()),
            _buildBottomBar(bottomPadding),
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
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
      child: Row(
        children: [
          // AI аватар
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_lightGreen, _primaryGreen],
              ),
              boxShadow: [
                BoxShadow(
                  color: _accentGreen.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                'images/ai.svg',
                width: 18.w,
                height: 18.w,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          // Текст
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.scanLabel,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  AppLocalizations.of(context)!.photographClothingLabel,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // Кнопка закрытия
          GestureDetector(
            onTap: _closeSheet,
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCamera() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          children: [
            // Камера - скрываем при закрытии чтобы камера успела освободиться
            if (!_isClosing && isInitialized && controller != null)
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: CameraPreview(controller!),
              )
            else
              Container(
                color: Colors.black,
                child: _isClosing ? null : const Center(
                  child: CircularProgressIndicator(
                    color: _accentGreen,
                    strokeWidth: 3,
                  ),
                ),
              ),

            // Затемнение по краям
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                  radius: 1.2,
                ),
              ),
            ),

            // Рамка сканирования
            Center(child: _buildScanFrame()),

            // Индикатор загрузки
            if (isLoading) _buildLoadingOverlay(),

            // Подсказка снизу
            Positioned(
              bottom: 16.h,
              left: 0,
              right: 0,
              child: _buildHint(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanFrame() {
    final frameSize = 240.w;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          children: [
            // Внешняя пульсирующая рамка
            Container(
              width: frameSize + (_pulseController.value * 12),
              height: frameSize + (_pulseController.value * 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: _accentGreen.withValues(alpha: 0.2 - (_pulseController.value * 0.15)),
                  width: 2,
                ),
              ),
            ),
            // Основная рамка с углами
            SizedBox(
              width: frameSize,
              height: frameSize,
              child: CustomPaint(
                painter: _CornerFramePainter(
                  color: _accentGreen,
                  cornerLength: 32.w,
                  strokeWidth: 4.w,
                  borderRadius: 20.r,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI анимация
            Container(
              width: 80.w,
              height: 80.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_lightGreen, _primaryGreen],
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 40.w,
                  height: 40.w,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              AppLocalizations.of(context)!.analyzingLabel,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppLocalizations.of(context)!.aiProcessingImage,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: _primaryGreen.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_laundry_service_rounded,
              color: _accentGreen,
              size: 18.w,
            ),
            SizedBox(width: 8.w),
            Text(
              AppLocalizations.of(context)!.washingSymbols,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h + bottomPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Кнопка вспышки
          _buildActionButton(
            icon: flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            isActive: flashOn,
            onTap: _toggleFlash,
          ),

          // Кнопка съёмки
          _buildCaptureButton(),

          // Placeholder для симметрии
          SizedBox(width: 56.w),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56.w,
        height: 56.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? _primaryGreen
              : Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: isActive
                ? _accentGreen.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? _accentGreen : Colors.white.withValues(alpha: 0.7),
          size: 24.w,
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: isInitialized && !isLoading ? _takePicture : null,
      child: Container(
        width: 80.w,
        height: 80.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_lightGreen, _primaryGreen],
          ),
          boxShadow: [
            BoxShadow(
              color: _accentGreen.withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          margin: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Center(
            child: Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 28.w,
            ),
          ),
        ),
      ),
    );
  }
}

// Painter для углов рамки
class _CornerFramePainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;
  final double borderRadius;

  _CornerFramePainter({
    required this.color,
    required this.cornerLength,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = borderRadius;
    final l = cornerLength;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(l, 0)
        ..lineTo(r, 0)
        ..arcToPoint(Offset(0, r), radius: Radius.circular(r))
        ..lineTo(0, l),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(w - l, 0)
        ..lineTo(w - r, 0)
        ..arcToPoint(Offset(w, r), radius: Radius.circular(r), clockwise: true)
        ..lineTo(w, l),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(w, h - l)
        ..lineTo(w, h - r)
        ..arcToPoint(Offset(w - r, h), radius: Radius.circular(r))
        ..lineTo(w - l, h),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, h - l)
        ..lineTo(0, h - r)
        ..arcToPoint(Offset(r, h), radius: Radius.circular(r), clockwise: false)
        ..lineTo(l, h),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Диалог предпросмотра фото
class _PhotoPreviewDialog extends StatelessWidget {
  final String photoPath;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;

  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _accentGreen = Color(0xFF8BC34A);

  const _PhotoPreviewDialog({
    required this.photoPath,
    required this.onConfirm,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20.w),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F12),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_rounded,
                    color: _accentGreen,
                    size: 24.w,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    l10n.photoPreview,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Изображение
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Image.file(
                  File(photoPath),
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Кнопки
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onRetake,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            l10n.retake,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: onConfirm,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5A6F2B), _primaryGreen],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 18.w,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                l10n.send,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

