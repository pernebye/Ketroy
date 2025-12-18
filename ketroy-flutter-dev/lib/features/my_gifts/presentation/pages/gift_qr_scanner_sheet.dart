import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/features/my_gifts/data/data_source/gift_data_source.dart';
import 'package:ketroy_app/features/my_gifts/presentation/pages/gift_selection_page.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Показать QR-сканер для активации подарков
Future<bool?> showGiftQrScannerSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => const GiftQrScannerSheet(),
  );
}

class GiftQrScannerSheet extends StatefulWidget {
  const GiftQrScannerSheet({super.key});

  @override
  State<GiftQrScannerSheet> createState() => _GiftQrScannerSheetState();
}

class _GiftQrScannerSheetState extends State<GiftQrScannerSheet>
    with SingleTickerProviderStateMixin {
  // Цвета
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);

  MobileScannerController? _scannerController;
  bool hasScanned = false;
  bool flashOn = false;
  bool isLoading = false;
  bool _isClosing = false;

  late AnimationController _pulseController;
  final GiftDataSourceImpl _giftDataSource = GiftDataSourceImpl();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (hasScanned || _isClosing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    hasScanned = true;
    HapticFeedback.mediumImpact();

    if (!mounted) return;

    setState(() => isLoading = true);

    // Проверяем подарки для активации
    _checkPendingGifts();
  }

  Future<void> _checkPendingGifts() async {
    try {
      final result = await _giftDataSource.activateByQr();

      if (!mounted) return;

      if (result.hasPendingGifts && result.gifts.isNotEmpty && result.giftGroupId != null) {
        // Есть подарки для выбора - открываем экран выбора
        _pulseController.stop();
        if (mounted) {
          Navigator.pop(context); // Закрываем scanner
        }

        final selected = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => GiftSelectionPage(
              giftGroupId: result.giftGroupId!,
              gifts: result.gifts,
            ),
          ),
        );

        if (selected == true && mounted) {
          showSnackBar(context, AppLocalizations.of(context)!.giftReceivedSuccess);
        }
      } else if (result.hasPendingGifts && result.giftGroupId == null) {
        // Ошибка: есть подарки, но нет giftGroupId
        _pulseController.stop();
        if (mounted) {
          Navigator.pop(context, false);
          showSnackBar(context, AppLocalizations.of(context)!.giftDataError);
        }
      } else {
        // Нет подарков для активации
        _pulseController.stop();
        if (mounted) {
          Navigator.pop(context, false);
          showSnackBar(context, result.message);
        }
      }
    } catch (e) {
      _pulseController.stop();
      if (mounted) {
        Navigator.pop(context, false);
        showSnackBar(context, AppLocalizations.of(context)!.giftActivationError);
      }
    }
  }

  void _toggleFlash() async {
    await _scannerController?.toggleTorch();
    setState(() => flashOn = !flashOn);
    HapticFeedback.lightImpact();
  }

  void _closeSheet() {
    if (_isClosing) return;
    _isClosing = true;

    _pulseController.stop();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
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
          _buildHandle(),
          _buildHeader(),
          Expanded(child: _buildScanner()),
          _buildBottomBar(bottomPadding),
        ],
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
          Container(
            width: 44.w,
            height: 44.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [_lightGreen, _primaryGreen]),
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: Colors.white,
              size: 22.w,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.activatingGift,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  AppLocalizations.of(context)!.scanQrAtStore,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
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
            // MobileScanner
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),

            // Overlay с вырезом
            _buildScannerOverlay(),

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
                        AppLocalizations.of(context)!.checkingGifts,
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

            // Подсказка
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
                        Icons.card_giftcard_rounded,
                        color: _accentGreen,
                        size: 16.w,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        AppLocalizations.of(context)!.qrCodeForGift,
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

  /// Создаём overlay с вырезом как у QrScannerOverlayShape
  Widget _buildScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = 220.w;
        final overlayColor = Colors.black.withValues(alpha: 0.8);

        return Stack(
          children: [
            // Затемнение сверху
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: (constraints.maxHeight - scanAreaSize) / 2,
              child: Container(color: overlayColor),
            ),
            // Затемнение снизу
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: (constraints.maxHeight - scanAreaSize) / 2,
              child: Container(color: overlayColor),
            ),
            // Затемнение слева
            Positioned(
              top: (constraints.maxHeight - scanAreaSize) / 2,
              left: 0,
              width: (constraints.maxWidth - scanAreaSize) / 2,
              height: scanAreaSize,
              child: Container(color: overlayColor),
            ),
            // Затемнение справа
            Positioned(
              top: (constraints.maxHeight - scanAreaSize) / 2,
              right: 0,
              width: (constraints.maxWidth - scanAreaSize) / 2,
              height: scanAreaSize,
              child: Container(color: overlayColor),
            ),
            // Рамка сканирования
            Center(
              child: Container(
                width: scanAreaSize,
                height: scanAreaSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: _accentGreen,
                    width: 4.w,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar(double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h + bottomPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
