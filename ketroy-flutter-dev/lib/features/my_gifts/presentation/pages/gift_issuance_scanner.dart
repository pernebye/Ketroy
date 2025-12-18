import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/features/my_gifts/data/data_source/gift_data_source.dart';
import 'package:ketroy_app/features/my_gifts/domain/entities/gifts_entities.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// Показать QR-сканер для подтверждения выдачи подарка
Future<bool?> showGiftIssuanceScannerSheet(
  BuildContext context, 
  GiftsEntities gift,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (context) => GiftIssuanceScannerSheet(gift: gift),
  );
}

class GiftIssuanceScannerSheet extends StatefulWidget {
  final GiftsEntities gift;
  
  const GiftIssuanceScannerSheet({super.key, required this.gift});

  @override
  State<GiftIssuanceScannerSheet> createState() => _GiftIssuanceScannerSheetState();
}

class _GiftIssuanceScannerSheetState extends State<GiftIssuanceScannerSheet>
    with SingleTickerProviderStateMixin {
  // Цвета
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);

  final qrKey = GlobalKey(debugLabel: 'IssuanceQR');
  QRViewController? qrViewController;
  StreamSubscription? _subscription;
  bool hasScanned = false;
  bool flashOn = false;
  bool isLoading = false;

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
    qrViewController?.pauseCamera();
    _pulseController.dispose();
    super.dispose();
  }

  /// Быстрая очистка без ожидания - камера освободится в dispose()
  void _quickCleanup() {
    _pulseController.stop();
    _subscription?.cancel();
    _subscription = null;
  }

  void _closeSheet() {
    _quickCleanup();
    if (mounted) {
      Navigator.pop(context);
    }
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

      // Подтверждаем выдачу подарка
      _confirmIssuance(scanData.code ?? '');
    });
  }

  Future<void> _confirmIssuance(String qrCode) async {
    debugPrint('🎁 Confirming issuance for gift ${widget.gift.id} with QR: $qrCode');
    
    try {
      final result = await _giftDataSource.confirmIssuance(
        giftId: widget.gift.id,
        qrCode: qrCode,
      );

      debugPrint('🎁 Issuance result: success=${result.success}, message=${result.message}');

      if (!mounted) return;

      if (result.success) {
        // Успешная выдача - сначала показываем диалог, потом закрываем
        HapticFeedback.heavyImpact();
        setState(() => isLoading = false);
        
        // Показываем диалог успеха
        await _showSuccessDialog();
        
        // После закрытия диалога - закрываем сканер с результатом true
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        // Ошибка выдачи - позволяем повторить сканирование
        HapticFeedback.lightImpact();
        _resetScanner();
        showSnackBar(context, result.message.isNotEmpty ? result.message : AppLocalizations.of(context)!.giftConfirmationError);
      }
    } catch (e) {
      debugPrint('❌ Issuance error: $e');
      if (mounted) {
        HapticFeedback.lightImpact();
        _resetScanner();
        
        // Более информативное сообщение об ошибке
        String errorMessage = AppLocalizations.of(context)!.giftConfirmationFailed;
        if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
          errorMessage = AppLocalizations.of(context)!.noInternetConnection;
        } else if (e.toString().contains('404')) {
          errorMessage = AppLocalizations.of(context)!.giftNotFound;
        } else if (e.toString().contains('403')) {
          errorMessage = AppLocalizations.of(context)!.giftNotYours;
        } else if (e.toString().contains('400')) {
          errorMessage = AppLocalizations.of(context)!.giftAlreadyIssued;
        }
        
        showSnackBar(context, errorMessage);
      }
    }
  }
  
  /// Сбросить сканер для повторного сканирования
  void _resetScanner() {
    setState(() {
      isLoading = false;
      hasScanned = false;
    });
    
    qrViewController?.resumeCamera();
    _subscription = qrViewController?.scannedDataStream.listen((scanData) async {
      if (hasScanned) return;
      hasScanned = true;
      await _subscription?.cancel();
      await qrViewController?.pauseCamera();
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      setState(() => isLoading = true);
      await _confirmIssuance(scanData.code ?? '');
    });
  }

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Изображение подарка
              if (widget.gift.image != null)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: Image.network(
                      widget.gift.image!,
                      width: 120.w,
                      height: 120.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7F0),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          Icons.card_giftcard_rounded,
                          size: 48.w,
                          color: _primaryGreen.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 20.h),
              
              // Поздравление
              Text(
                'Подарок получен!',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: _primaryGreen,
                ),
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  widget.gift.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                AppLocalizations.of(context)!.showEmployeeMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 24.h),
              
              // Кнопка
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_lightGreen, _primaryGreen],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.excellent,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFlash() async {
    await qrViewController?.toggleFlash();
    setState(() => flashOn = !flashOn);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _quickCleanup();
          if (mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
            _buildGiftInfo(),
            Expanded(child: _buildScanner()),
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
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
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
              Icons.qr_code_scanner_rounded,
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
                  AppLocalizations.of(context)!.receivingGift,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  AppLocalizations.of(context)!.scanGiftAtCheckout,
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

  Widget _buildGiftInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _accentGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Изображение подарка
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: widget.gift.image != null
                  ? Image.network(
                      widget.gift.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.card_giftcard_rounded,
                        color: _accentGreen,
                        size: 28.w,
                      ),
                    )
                  : Icon(
                      Icons.card_giftcard_rounded,
                      color: _accentGreen,
                      size: 28.w,
                    ),
            ),
          ),
          SizedBox(width: 14.w),
          // Информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.yourGift,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  widget.gift.name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Container(
      margin: EdgeInsets.all(20.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          children: [
            QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: _accentGreen,
                borderRadius: 20.r,
                borderLength: 32.w,
                borderWidth: 4.w,
                cutOutSize: 200.w,
                overlayColor: Colors.black.withValues(alpha: 0.8),
              ),
            ),
            
            // Анимированная рамка
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 204.w + (_pulseController.value * 8),
                    height: 204.w + (_pulseController.value * 8),
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
                        AppLocalizations.of(context)!.confirmingIssue,
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
              bottom: 16.h,
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
                        Icons.storefront_rounded,
                        color: _accentGreen,
                        size: 16.w,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        AppLocalizations.of(context)!.qrCodeAtCheckout,
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
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h + bottomPadding),
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

