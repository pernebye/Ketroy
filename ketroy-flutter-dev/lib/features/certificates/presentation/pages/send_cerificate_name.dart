import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart';
import 'package:ketroy_app/core/common/widgets/profile_textfield.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/features/certificates/presentation/pages/name_certificate.dart';
import 'package:ketroy_app/features/certificates/widgets/certificate.dart';

class SendCerificateName extends StatelessWidget {
  final int price;
  SendCerificateName({super.key, required this.price});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController wordsController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 35.w),
        child: Form(
          key: _formKey,
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
                price: price.toString(),
                sendCertificate: true,
              ),
              SizedBox(
                height: 20.h,
              ),
              ProfileTextField(
                hint: 'ФИО',
                controller: nameController,
              ),
              SizedBox(
                height: 20.h,
              ),
              ProfileTextField(
                hint: 'Номер телефона',
                controller: phoneController,
              ),
              SizedBox(
                height: 20.h,
              ),
              ProfileTextField(
                hint: 'Добавить поздравление',
                controller: wordsController,
              ).copyWith(boxHeight: 105, height: 123),
              SizedBox(
                height: 20.h,
              ),
              Row(
                children: [
                  Expanded(
                      child: AppButton(
                          title: 'Продолжить',
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const NameCertificate(
                                              price: '10000',
                                              name: 'Zhalgas')));
                            }
                          },
                          backgroundColor: Colors.black)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
