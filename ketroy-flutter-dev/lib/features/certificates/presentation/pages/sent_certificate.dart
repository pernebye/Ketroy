import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/entities/menu.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart';
import 'package:ketroy_app/core/common/widgets/dropdown_field.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/features/certificates/presentation/pages/send_cerificate_name.dart';
import 'package:ketroy_app/features/certificates/widgets/certificate.dart';

class SendCertificatePage extends StatefulWidget {
  const SendCertificatePage({super.key});

  @override
  State<SendCertificatePage> createState() => _SendCertificatePageState();
}

class _SendCertificatePageState extends State<SendCertificatePage> {
  String? _selectedValue = '30000';
  final List<Menu> _options = [
    Menu(name: '30000', value: 10000, image: const SizedBox()),
    Menu(name: '50000', value: 15000, image: const SizedBox()),
    Menu(name: '100000', value: 20000, image: const SizedBox()),
    Menu(name: '150000', value: 20000, image: const SizedBox()),
    Menu(name: '200000', value: 20000, image: const SizedBox()),
    Menu(name: '250000', value: 20000, image: const SizedBox()),
    Menu(name: '300000', value: 20000, image: const SizedBox()),
    Menu(name: '350000', value: 20000, image: const SizedBox()),
    Menu(name: '500000', value: 20000, image: const SizedBox()),
    Menu(name: '1000000', value: 20000, image: const SizedBox()),
  ];
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
                  'Подарить сертификат',
                  style: AppTheme.certificateTitleTextStyle
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(
              height: 20.h,
            ),
            Certificate(
              price: _selectedValue ?? "",
              sendCertificate: true,
            ),
            SizedBox(
              height: 20.h,
            ),
            SizedBox(
              height: 71.h,
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  DropDownField(
                      labelText: _selectedValue ?? '',
                      selectedValue: _selectedValue,
                      onChanged: (String? newValue) {
                        FocusScope.of(context).requestFocus(FocusNode());
                        setState(() {
                          _selectedValue = newValue;
                        });
                      },
                      options: _options),
                  Positioned(
                      top: 4.h,
                      left: 20.w,
                      child: Container(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                              vertical: 5.h, horizontal: 8.w),
                          child: const Text(
                            'Выберите номинал',
                          )))
                ],
              ),
            ),
            SizedBox(
              height: 20.h,
            ),
            Row(
              children: [
                Expanded(
                    child: AppButton(
                        title: 'Продолжить',
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      SendCerificateName(price: 100000)));
                        },
                        backgroundColor: Colors.black)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
