import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/features/certificates/widgets/certificate.dart';

class NameCertificate extends StatelessWidget {
  final String price;
  final String name;

  const NameCertificate({super.key, required this.price, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 35.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 190.w,
                  child: Text(
                    textAlign: TextAlign.center,
                    'Поздравляем ваш подарок отправлен!',
                    style: AppTheme.certificateTitleTextStyle
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20.h,
            ),
            Certificate(
              price: price,
              sendCertificate: true,
            ),
            SizedBox(
              height: 20.h,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    width: 190.w,
                    child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: 'Вы успешно отправили подарок ',
                                style: AppTheme.certificateTitleTextStyle
                                    .copyWith(color: Colors.black)),
                            TextSpan(
                                text: name,
                                style: AppTheme.certificateTitleTextStyle
                                    .copyWith(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
                          ],
                        )))
              ],
            ),
            SizedBox(
              height: 20.h,
            ),
            Row(
              children: [
                Expanded(
                    child: AppButton(
                        title: 'Подарить еще',
                        onPressed: () {},
                        backgroundColor: Colors.black)),
              ],
            ),
            SizedBox(
              height: 20.h,
            ),
            Row(
              children: [
                Expanded(
                    child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(8.r)),
                  child: AppButton(
                      title: 'Вернуться назад',
                      onPressed: () {},
                      backgroundColor: Colors.white),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
