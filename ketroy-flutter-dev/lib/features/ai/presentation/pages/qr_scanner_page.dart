import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ketroy_app/features/ai/presentation/bloc/ai_bloc.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:ketroy_app/services/localization/localization_service.dart';

class CameraPhotoPage extends StatefulWidget {
  const CameraPhotoPage({super.key});

  @override
  State<CameraPhotoPage> createState() => _CameraPhotoPageState();
}

class _CameraPhotoPageState extends State<CameraPhotoPage> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  bool isInitialized = false;
  bool flashOn = false;
  bool isRearCamera = true;

  @override
  void initState() {
    super.initState();
    // Устанавливаем портретную ориентацию
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _initializeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    // Возвращаем обычные ориентации
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras!.isNotEmpty) {
        controller = CameraController(
          cameras![0], // Задняя камера по умолчанию
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.bgra8888,
        );

        await controller!.initialize();
        setState(() {
          isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Ошибка инициализации камеры: $e');
    }
  }

  Future<void> _takePicture() async {
    if (controller == null || !controller!.value.isInitialized) return;

    try {
      final XFile photo = await controller!.takePicture();
      _showPhotoPreview(photo);
    } catch (e) {
      debugPrint('Error taking photo: $e');
      final l10n = AppLocalizations.of(context)!;
      _showErrorSnackBar(l10n.photoError);
    }
  }

  void _showPhotoPreview(XFile photo) {
    showDialog(
      context: context,
      builder: (context) => PhotoPreviewDialog(
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
    try {
      // Преобразуем XFile в File
      final file = File(photo.path);

      // Получаем правильный код языка для AI напрямую из LocalizationService singleton
      final locService = serviceLocator<LocalizationService>();
      final languageCode = locService.getLanguageCodeForAI();
      debugPrint('📤 CameraPhotoPage: Uploading photo with language: $languageCode');

      // Отправляем через BLoC с языком
      context.read<AiBloc>().add(
        SendImageToServerFetch(imageFile: file, languageCode: languageCode),
      );
    } catch (e) {
      // Показываем ошибку
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.photoLoadError)),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (controller != null) {
      try {
        await controller!.setFlashMode(
          flashOn ? FlashMode.off : FlashMode.torch,
        );
        setState(() {
          flashOn = !flashOn;
        });
      } catch (e) {
        debugPrint('Ошибка переключения вспышки: $e');
      }
    }
  }

  // Future<void> _switchCamera() async {
  //   if (cameras == null || cameras!.length < 2) return;

  //   try {
  //     setState(() {
  //       isInitialized = false;
  //     });

  //     await controller?.dispose();

  //     controller = CameraController(
  //       cameras![isRearCamera ? 1 : 0], // Переключаем камеру
  //       ResolutionPreset.high,
  //       enableAudio: false,
  //     );

  //     await controller!.initialize();

  //     setState(() {
  //       isInitialized = true;
  //       isRearCamera = !isRearCamera;
  //       flashOn = false; // Сбрасываем вспышку при переключении
  //     });
  //   } catch (e) {
  //     print('Ошибка переключения камеры: $e');
  //     _showErrorSnackBar('Ошибка переключения камеры');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<AiBloc, AiState>(
        listener: (context, state) {
          if (state.isSuccess) {
            // Успешная отправка - возвращаемся назад
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.imageSentForAnalysis),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state.isFailure) {
            // Ошибка - показываем сообщение
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message ?? l10n.sendError),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isUploading = state.isLoading;

          return Stack(
            children: [
              // Камера на весь экран
              if (isInitialized && controller != null)
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CameraPreview(controller!),
                )
              else
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.orange,
                  ),
                ),

              // Рамка для фокуса
              _buildFocusFrame(),

              // Верхняя панель
              _buildTopBar(),

              // Нижняя панель
              _buildBottomBar(),

              // Индикатор загрузки
              if (isUploading)
                Container(
                  color: Colors.black.withValues(alpha: 0.8),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.orange,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Отправляем изображение на анализ...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Пожалуйста, подождите',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFocusFrame() {
    final screenSize = MediaQuery.of(context).size;
    final frameSize = screenSize.width * 0.7;
    final left = (screenSize.width - frameSize) / 2;
    final top = (screenSize.height - frameSize) / 2;

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: frameSize,
        height: frameSize,
        decoration: BoxDecoration(
          // border: Border.all(
          //   color: Colors.orange.withValues(alpha: 0.8),
          //   width: 2,
          // ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Углы
            ...List.generate(4, (index) {
              return Positioned(
                left: index == 0 || index == 3 ? 0 : frameSize - 30,
                top: index < 2 ? 0 : frameSize - 30,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    // ✅ Добавляем округление для каждого угла
                    borderRadius: BorderRadius.only(
                      topLeft:
                          index == 0 ? const Radius.circular(17) : Radius.zero,
                      topRight:
                          index == 1 ? const Radius.circular(17) : Radius.zero,
                      bottomRight:
                          index == 2 ? const Radius.circular(17) : Radius.zero,
                      bottomLeft:
                          index == 3 ? const Radius.circular(17) : Radius.zero,
                    ),
                    border: Border(
                      left: index == 0 || index == 3
                          ? const BorderSide(color: Colors.orange, width: 4)
                          : BorderSide.none,
                      right: index == 1 || index == 2
                          ? const BorderSide(color: Colors.orange, width: 4)
                          : BorderSide.none,
                      top: index < 2
                          ? const BorderSide(color: Colors.orange, width: 4)
                          : BorderSide.none,
                      bottom: index > 1
                          ? const BorderSide(color: Colors.orange, width: 4)
                          : BorderSide.none,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.pointCameraAtLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Кнопка фонарика (только для задней камеры)
                  if (isRearCamera)
                    GestureDetector(
                      onTap: _toggleFlash,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          flashOn ? Icons.flash_on : Icons.flash_off,
                          color: flashOn ? Colors.orange : Colors.white,
                          size: 28,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 60),

                  // Кнопка съемки
                  GestureDetector(
                    onTap: isInitialized ? _takePicture : null,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 60), // Пустое место для симметрии
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Диалог предпросмотра фото
class PhotoPreviewDialog extends StatelessWidget {
  final String photoPath;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;

  const PhotoPreviewDialog({
    super.key,
    required this.photoPath,
    required this.onConfirm,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.photoPreview,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Изображение
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Image.file(
              File(photoPath),
              fit: BoxFit.contain,
            ),
          ),

          // Кнопки
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: onRetake,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(l10n.retake),
                ),
                TextButton(
                  onPressed: onConfirm,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(l10n.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
