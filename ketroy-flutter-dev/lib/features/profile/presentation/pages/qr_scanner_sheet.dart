import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/widgets/top_toast.dart';
import 'package:ketroy_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:ketroy_app/main.dart' show navigatorKey;
import 'package:mobile_scanner/mobile_scanner.dart';

/// Показать QR-сканер как нижнюю шторку
Future<bool?> showQrScannerSheet(BuildContext context) {
  final profileBloc = context.read<ProfileBloc>();
  profileBloc.add(ResetQrStatus());

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    isDismissible: true,
    enableDrag: true,
    builder: (sheetContext) => BlocProvider.value(
      value: profileBloc,
      child: const QrScannerSheet(),
    ),
  );
}

class QrScannerSheet extends StatefulWidget {
  const QrScannerSheet({super.key});

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet>
    with SingleTickerProviderStateMixin {
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _accentGreen = Color(0xFF8BC34A);

  MobileScannerController? _scannerController;
  bool hasScanned = false;
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

    final l10n = AppLocalizations.of(context);

    if (!_isValidDiscountQrCode(code)) {
      _closeSheet();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final overlay = navigatorKey.currentState?.overlay;
        final ctx = navigatorKey.currentContext;
        if (overlay != null && ctx != null) {
          TopToast.showWarning(
            ctx,
            message: l10n?.invalidQrCode ?? 'Неверный QR-код. Используйте QR-код из магазина KETROY',
            overlayState: overlay,
          );
        }
      });
      return;
    }

    setState(() => isLoading = true);
    context.read<ProfileBloc>().add(ScanQrFetch(scanQrUrl: code));
  }

  bool _isValidDiscountQrCode(String code) {
    try {
      final uri = Uri.parse(code);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) return false;

      final host = uri.host.toLowerCase();
      final isKetroyApi = host.contains('ketroy-shop.kz') ||
                          host.contains('ketroy.kz') ||
                          host.contains('ketroy.ngrok.app');
      final isLocalDev = host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';

      if (!isKetroyApi && !isLocalDev) return false;

      final path = uri.path.toLowerCase();
      return path.contains('scan-discount');
    } catch (e) {
      return false;
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

    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) =>
        previous.qrStatus != current.qrStatus &&
        (current.isQrSuccess || current.isQrFailure),
      listener: (context, state) {
        if (state.isQrSuccess) {
          final successMessage = AppLocalizations.of(context)!.qrCodeScannedSuccess;
          if (mounted) {
            context.read<ProfileBloc>().add(ResetQrStatus());
            Navigator.pop(context, true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final overlay = navigatorKey.currentState?.overlay;
              final ctx = navigatorKey.currentContext;
              if (overlay != null && ctx != null) {
                TopToast.showSuccess(ctx, message: successMessage, overlayState: overlay);
              }
            });
          }
        } else if (state.isQrFailure) {
          final errorMessage = state.message ?? 'Ошибка сканирования';
          if (mounted) {
            context.read<ProfileBloc>().add(ResetQrStatus());
            Navigator.pop(context, false);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final overlay = navigatorKey.currentState?.overlay;
              final ctx = navigatorKey.currentContext;
              if (overlay != null && ctx != null) {
                TopToast.showError(ctx, message: errorMessage, overlayState: overlay);
              }
            });
          }
        }
      },
      child: Container(
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
                  AppLocalizations.of(context)!.scanQr,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  AppLocalizations.of(context)!.pointCameraAtQr,
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
            // Camera
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),

            // Overlay
            _buildScannerOverlay(),

            // Loading
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
                        'Обработка...',
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

            // Hint
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
                    AppLocalizations.of(context)!.qrCodeInStore,
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
            // Dark overlay with cutout
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _OverlayPainter(
                scanAreaSize: scanAreaSize,
                borderRadius: cornerRadius,
              ),
            ),

            // Corner brackets with animation
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
                    // Top-left corner
                    Positioned(
                      left: left,
                      top: top,
                      child: _buildCorner(cornerLength, cornerWidth, cornerRadius, color, TopLeft()),
                    ),
                    // Top-right corner
                    Positioned(
                      right: left,
                      top: top,
                      child: _buildCorner(cornerLength, cornerWidth, cornerRadius, color, TopRight()),
                    ),
                    // Bottom-left corner
                    Positioned(
                      left: left,
                      bottom: top,
                      child: _buildCorner(cornerLength, cornerWidth, cornerRadius, color, BottomLeft()),
                    ),
                    // Bottom-right corner
                    Positioned(
                      right: left,
                      bottom: top,
                      child: _buildCorner(cornerLength, cornerWidth, cornerRadius, color, BottomRight()),
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

// Corner position markers
abstract class _CornerPosition {}
class TopLeft extends _CornerPosition {}
class TopRight extends _CornerPosition {}
class BottomLeft extends _CornerPosition {}
class BottomRight extends _CornerPosition {}

// Overlay painter with rounded cutout
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

// Corner bracket painter
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

    if (position is TopLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
      path.lineTo(size.width, 0);
    } else if (position is TopRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height);
    } else if (position is BottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height - radius);
      path.quadraticBezierTo(0, size.height, radius, size.height);
      path.lineTo(size.width, size.height);
    } else if (position is BottomRight) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height - radius);
      path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color;
}
