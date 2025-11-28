import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<StatefulWidget> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  StreamSubscription? _subscription;
  bool hasScanend = false;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          return Column(
            children: [
              SizedBox(
                height: 80.h,
              ),
              Container(
                width: double.infinity,
                height: 723.h,
                decoration: BoxDecoration(
                    color: const Color(0x804A7053),
                    borderRadius: BorderRadius.circular(32.r)),
                child: Column(children: [
                  SizedBox(
                    height: 19.h,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 27.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 35.w,
                            height: 35.h,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFF2F2F2)),
                            child: const Icon(Icons.chevron_left),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 9.w, vertical: 9.h),
                          width: 35.w,
                          height: 35.h,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Color(0xFFF2F2F2)),
                          child: SvgPicture.asset('images/bell1.svg'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 140.h,
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(41.r),
                    child: SizedBox(
                      width: 230.w,
                      height: 230.h,
                      child: (state.isQrLoading)
                          ? const Loader()
                          : Center(
                              child: QRView(
                                key: qrKey,
                                onQRViewCreated: _onQRViewCreated,
                                overlay: QrScannerOverlayShape(
                                    borderColor: const Color(0xFFF99A0B),
                                    borderRadius: 17.r,
                                    borderLength: 30.h,
                                    borderWidth: 10.w,
                                    cutOutSize:
                                        MediaQuery.of(context).size.width * 0.5,
                                    overlayColor: Colors.black),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(
                    height: 20.h,
                  ),
                  SizedBox(
                      width: 222.w,
                      child: Text(
                        'Отсканируйте QR код для просмотра бонусов и скидки',
                        textAlign: TextAlign.center,
                        style: AppTheme.qrScreenTextStyle
                            .copyWith(color: Colors.white),
                      ))
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onQRViewCreated(QRViewController qrController) {
    controller = qrController;
    _subscription = controller!.scannedDataStream.listen((scanData) async {
      if (hasScanend) return;
      hasScanend = true;

      await _subscription?.cancel();
      await controller?.pauseCamera();

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
}
