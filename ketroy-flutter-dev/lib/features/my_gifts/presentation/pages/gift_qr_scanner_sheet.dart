import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/features/my_gifts/data/data_source/gift_data_source.dart';
import 'package:ketroy_app/features/my_gifts/presentation/pages/gift_selection_page.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

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

  final qrKey = GlobalKey(debugLabel: 'GiftQR');
  QRViewController? qrViewController;
  StreamSubscription? _subscription;
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
  }

  @override
  void dispose() {
    _pulseController.stop();
    _subscription?.cancel();
    // Не вызываем dispose() для qrViewController - это вызывает краш на iOS
    // Камера сама освободится когда QRView будет удалён из дерева
    _pulseController.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    qrViewController = controller;
    _subscription = controller.scannedDataStream.listen((scanData) {
      if (hasScanned) return;
      hasScanned = true;

      // Быстрая очистка подписки (камера освободится в dispose)
      _subscription?.cancel();
      _subscription = null;

      HapticFeedback.mediumImpact();

      if (!mounted) return;

      setState(() => isLoading = true);

      // Проверяем подарки для активации
      _checkPendingGifts();
    });
  }

  Future<void> _checkPendingGifts() async {
    try {
      final result = await _giftDataSource.activateByQr();

      if (!mounted) return;

      if (result.hasPendingGifts && result.gifts.isNotEmpty && result.giftGroupId != null) {
        // Есть подарки для выбора - открываем экран выбора
        _quickCleanup();
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
        _quickCleanup();
        if (mounted) {
          Navigator.pop(context, false);
          showSnackBar(context, AppLocalizations.of(context)!.giftDataError);
        }
      } else {
        // Нет подарков для активации
        _quickCleanup();
        if (mounted) {
          Navigator.pop(context, false);
          showSnackBar(context, result.message);
        }
      }
    } catch (e) {
      _quickCleanup();
      if (mounted) {
        Navigator.pop(context, false);
        showSnackBar(context, AppLocalizations.of(context)!.giftActivationError);
      }
    }
  }

  void _toggleFlash() async {
    await qrViewController?.toggleFlash();
    setState(() => flashOn = !flashOn);
    HapticFeedback.lightImpact();
  }

  /// Быстрая очистка без ожидания - камера освободится в dispose()
  void _quickCleanup() {
    _pulseController.stop();
    _subscription?.cancel();
    _subscription = null;
  }

  void _closeSheet() {
    if (_isClosing) return;
    _isClosing = true;

    _quickCleanup();

    // Закрываем sheet НЕМЕДЛЕННО
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Убрали PopScope - пусть sheet закрывается свободно,
    // камера освободится в dispose()
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
