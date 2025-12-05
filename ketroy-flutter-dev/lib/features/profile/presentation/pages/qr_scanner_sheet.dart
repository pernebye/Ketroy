import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// Показать QR-сканер как нижнюю шторку
Future<bool?> showQrScannerSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true, // Открываем поверх навбара
    isDismissible: true,
    enableDrag: true,
    builder: (context) => const QrScannerSheet(),
  );
}

class QrScannerSheet extends StatefulWidget {
  const QrScannerSheet({super.key});

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet>
    with SingleTickerProviderStateMixin {
  // Цвета
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);

  final qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrViewController;
  StreamSubscription? _subscription;
  bool hasScanend = false;
  bool flashOn = false;
  bool isLoading = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.stop();
    _subscription?.cancel();
    qrViewController?.pauseCamera();
    qrViewController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    qrViewController = controller;
    _subscription = controller.scannedDataStream.listen((scanData) async {
      if (hasScanend) return;
      hasScanend = true;

      await _subscription?.cancel();
      await qrViewController?.pauseCamera();

      // Вибрация при сканировании
      HapticFeedback.mediumImpact();

      if (!mounted) return;

      final code = scanData.code;
      if (code == null || code.isEmpty) {
        await _cleanupResources();
        if (mounted) {
          Navigator.pop(context, false);
          showSnackBar(context, 'QR-код пустой или повреждён');
        }
        return;
      }
      
      // Валидация URL - проверяем, что это правильный QR-код для скидки
      if (!_isValidDiscountQrCode(code)) {
        await _cleanupResources();
        if (mounted) {
          Navigator.pop(context, false);
          showSnackBar(context, 'Неверный QR-код. Используйте QR-код из магазина KETROY');
        }
        return;
      }

      setState(() => isLoading = true);
      context.read<ProfileBloc>().add(ScanQrFetch(scanQrUrl: code));
    });
  }
  
  /// Проверяет, что URL является валидным QR-кодом для скидки Ketroy
  bool _isValidDiscountQrCode(String code) {
    try {
      final uri = Uri.parse(code);
      
      // Проверяем, что это URL (а не просто текст)
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        debugPrint('❌ QR код не является URL: $code');
        return false;
      }
      
      // Проверяем, что это URL Ketroy API или localhost/ngrok для dev
      final host = uri.host.toLowerCase();
      final isKetroyApi = host.contains('ketroy-shop.kz') || 
                          host.contains('ketroy.kz') ||
                          host.contains('ketroy.ngrok.app');
      final isLocalDev = host == 'localhost' || 
                         host == '127.0.0.1' || 
                         host == '10.0.2.2';
      
      if (!isKetroyApi && !isLocalDev) {
        debugPrint('❌ QR код не от Ketroy: $code');
        return false;
      }
      
      // Проверяем, что путь содержит scan-discount
      final path = uri.path.toLowerCase();
      if (!path.contains('scan-discount')) {
        debugPrint('❌ QR код не для скидки: $code');
        return false;
      }
      
      debugPrint('✅ Валидный QR код для скидки: $code');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка парсинга QR кода: $e');
      return false;
    }
  }

  void _toggleFlash() async {
    await qrViewController?.toggleFlash();
    setState(() => flashOn = !flashOn);
    HapticFeedback.lightImpact();
  }

  Future<void> _cleanupResources() async {
    // Останавливаем анимацию
    _pulseController.stop();
    
    // Отменяем подписку
    await _subscription?.cancel();
    _subscription = null;
    
    // Останавливаем камеру
    await qrViewController?.pauseCamera();
    qrViewController?.dispose();
    qrViewController = null;
  }

  Future<void> _closeSheet() async {
    await _cleanupResources();
    
    // Закрываем шторку
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _cleanupResources();
          if (mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) async {
          if (state.isQrSuccess) {
            await _cleanupResources();
            if (mounted) {
              Navigator.pop(context, true);
              showSnackBar(context, AppLocalizations.of(context)!.qrCodeScannedSuccess);
            }
          } else if (state.isQrFailure) {
            await _cleanupResources();
            if (mounted) {
              Navigator.pop(context, false);
              showSnackBar(context, state.message ?? 'Ошибка сканирования');
            }
          }
        },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28.r),
            topRight: Radius.circular(28.r),
          ),
        ),
        child: Column(
          children: [
            // Хэндл для закрытия
            _buildHandle(),

            // Заголовок
            _buildHeader(),

            // QR-сканер
            Expanded(child: _buildScanner()),

            // Нижняя панель с кнопками
            _buildBottomBar(bottomPadding),
          ],
        ),
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
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
      child: Row(
        children: [
          // Иконка
          Container(
            width: 44.w,
            height: 44.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_lightGreen, _primaryGreen],
              ),
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 22.w,
            ),
          ),
          SizedBox(width: 14.w),
          // Текст
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.scanQr,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  AppLocalizations.of(context)!.pointCameraAtQr,
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

  Widget _buildScanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          children: [
            // QR View
            QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: _accentGreen,
                borderRadius: 20.r,
                borderLength: 32.w,
                borderWidth: 4.w,
                cutOutSize: 220.w,
                overlayColor: Colors.black.withValues(alpha: 0.8),
              ),
            ),

            // Анимированная рамка
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 224.w + (_pulseController.value * 8),
                    height: 224.w + (_pulseController.value * 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22.r),
                      border: Border.all(
                        color: _accentGreen
                            .withValues(alpha: 0.3 - (_pulseController.value * 0.2)),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Индикатор загрузки
            if (isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48.w,
                        height: 48.w,
                        child: const CircularProgressIndicator(
                          color: _accentGreen,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Обработка...',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Подсказка снизу сканера
            Positioned(
              bottom: 20.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: _accentGreen,
                        size: 16.w,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        AppLocalizations.of(context)!.qrCodeInStore,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
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

  Widget _buildBottomBar(double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h + bottomPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Кнопка вспышки
          _buildActionButton(
            icon: flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            label: flashOn ? AppLocalizations.of(context)!.flashOff : AppLocalizations.of(context)!.flashOn,
            isActive: flashOn,
            onTap: _toggleFlash,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isActive
              ? _primaryGreen
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isActive
                ? _accentGreen.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? _accentGreen : Colors.white.withValues(alpha: 0.7),
              size: 22.w,
            ),
            SizedBox(width: 10.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
