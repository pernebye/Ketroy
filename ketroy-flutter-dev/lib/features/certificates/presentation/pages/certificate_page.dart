import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/features/certificates/widgets/certificate.dart';

class CertificatePage extends StatelessWidget {
  const CertificatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 35.w),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Подарочные сертификат',
                  style: AppTheme.certificateTitleTextStyle
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(
              height: 20.h,
            ),
            const Certificate(
              price: '10000',
              sendCertificate: false,
            ),
            SizedBox(
              height: 20.h,
            ),
          ],
        ),
      ),
    );
  }
}
