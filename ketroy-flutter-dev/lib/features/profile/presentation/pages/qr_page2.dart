import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';

import 'package:ketroy_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class CameraPhotoPage1 extends StatefulWidget {
  const CameraPhotoPage1({super.key});

  @override
  State<CameraPhotoPage1> createState() => _CameraPhotoPage1State();
}

class _CameraPhotoPage1State extends State<CameraPhotoPage1> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  bool isInitialized = false;
  bool flashOn = false;
  bool isRearCamera = true;
  final qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrViewController;
  StreamSubscription? _subscription;
  bool hasScanend = false;

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
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras!.isNotEmpty) {
        controller = CameraController(
          cameras![0], // Задняя камера по умолчанию
          ResolutionPreset.high,
          enableAudio: false,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.isQrSuccess) {
            if (Navigator.canPop(context)) {
              context.read<ProfileBloc>().add(GetDiscountFetch());
              Navigator.pop(context);
            }
          } else if (state.isQrFailure) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              showSnackBar(context, state.message ?? '');
            }
          }
        },
        builder: (context, state) {
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

              _buildFocusFrame(),
              // Верхняя панель
              _buildTopBar(),

              // Индикатор загрузки
            ],
          );
        },
      ),
    );
  }

  void _onQRViewCreated(QRViewController qrController) {
    qrViewController = qrController;
    _subscription =
        qrViewController!.scannedDataStream.listen((scanData) async {
      if (hasScanend) return;
      hasScanend = true;

      await _subscription?.cancel();
      await qrViewController?.pauseCamera();

      if (!mounted) {
        return;
      }

      final code = scanData.code;
      if (code != null) {
        context.read<ProfileBloc>().add(ScanQrFetch(scanQrUrl: scanData.code!));
      }
    });
  }

  String path(String? scanData) {
    final url = Uri.parse(scanData ?? '');
    var path = url.path;
    if (path.startsWith('/api/')) {
      path = path.replaceFirst('/api', '');
    }
    return path;
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(41.r),
          child: SizedBox(
            width: 230.w,
            height: 230.h,
            child: Center(
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                    borderColor: const Color(0xFFF99A0B),
                    borderRadius: 17.r,
                    borderLength: 30.h,
                    borderWidth: 10.w,
                    cutOutSize: MediaQuery.of(context).size.width * 0.5,
                    overlayColor: Colors.black),
              ),
            ),
          ),
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
}
