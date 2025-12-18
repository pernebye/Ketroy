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
  static const Color _primaryGreen = Color(0xFF3C4B1B);
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
      duration: const Duration(milliseconds: 2000),
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
    _checkPendingGifts();
  }

  Future<void> _checkPendingGifts() async {
    try {
      final result = await _giftDataSource.activateByQr();

      if (!mounted) return;

      if (result.hasPendingGifts && result.gifts.isNotEmpty && result.giftGroupId != null) {
        _pulseController.stop();
        if (mounted) Navigator.pop(context);

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
        _pulseController.stop();
        if (mounted) {
          Navigator.pop(context, false);
          showSnackBar(context, AppLocalizations.of(context)!.giftDataError);
        }
      } else {
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
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
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
      width: 36.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.activatingGift,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  AppLocalizations.of(context)!.scanQrAtStore,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _closeSheet,
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 22.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          children: [
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),

            _buildScannerOverlay(),

            if (isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 40.w,
                        height: 40.w,
                        child: const CircularProgressIndicator(
                          color: _accentGreen,
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        AppLocalizations.of(context)!.checkingGifts,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Positioned(
              bottom: 16.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.qrCodeForGift,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = 240.w;
        final cornerLength = 28.w;
        final cornerWidth = 4.w;
        final cornerRadius = 12.r;

        final left = (constraints.maxWidth - scanAreaSize) / 2;
        final top = (constraints.maxHeight - scanAreaSize) / 2;

        return Stack(
          children: [
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _OverlayPainter(
                scanAreaSize: scanAreaSize,
                borderRadius: cornerRadius,
              ),
            ),

            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final color = Color.lerp(
                  _accentGreen,
                  _accentGreen.withValues(alpha: 0.6),
                  _pulseController.value,
                )!;

                return Stack(
                  children: [
                    Positioned(
                      left: left,
                      top: top,
                      child: _buildCorner(cornerLength, cornerWidth, cornerRadius, color, _TopLeft()),
                    ),
                    Positioned(
                      right: left,
                      top: top,
                      child: _buildCorner(cornerLength, cornerWidth, cornerRadius, color, _TopRight()),
                    ),
                    Positioned(
                      left: left,
                      bottom: top,
                      child: _buildCorner(cornerLength, cornerWidth, cornerRadius, color, _BottomLeft()),
                    ),
                    Positioned(
                      right: left,
                      bottom: top,
                      child: _buildCorner(cornerLength, cornerWidth, cornerRadius, color, _BottomRight()),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCorner(double length, double width, double radius, Color color, _CornerPosition position) {
    return CustomPaint(
      size: Size(length, length),
      painter: _CornerPainter(
        color: color,
        strokeWidth: width,
        radius: radius,
        position: position,
      ),
    );
  }

  Widget _buildBottomBar(double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h + bottomPadding),
      child: GestureDetector(
        onTap: _toggleFlash,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: flashOn
                ? _primaryGreen.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: flashOn
                  ? _accentGreen.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: flashOn ? _accentGreen : Colors.white.withValues(alpha: 0.6),
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                flashOn
                    ? AppLocalizations.of(context)!.flashOff
                    : AppLocalizations.of(context)!.flashOn,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: flashOn ? Colors.white : Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract class _CornerPosition {}
class _TopLeft extends _CornerPosition {}
class _TopRight extends _CornerPosition {}
class _BottomLeft extends _CornerPosition {}
class _BottomRight extends _CornerPosition {}

class _OverlayPainter extends CustomPainter {
  final double scanAreaSize;
  final double borderRadius;

  _OverlayPainter({required this.scanAreaSize, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.7);

    final cutoutRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: scanAreaSize,
        height: scanAreaSize,
      ),
      Radius.circular(borderRadius),
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(cutoutRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final _CornerPosition position;

  _CornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.position,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (position is _TopLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
      path.lineTo(size.width, 0);
    } else if (position is _TopRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height);
    } else if (position is _BottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height - radius);
      path.quadraticBezierTo(0, size.height, radius, size.height);
      path.lineTo(size.width, size.height);
    } else if (position is _BottomRight) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height - radius);
      path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => oldDelegate.color != color;
}
