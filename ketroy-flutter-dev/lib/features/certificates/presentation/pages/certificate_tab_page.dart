import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart';
import 'package:ketroy_app/core/constants/shop_contacts.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/core/util/launch_url.dart';
import 'package:ketroy_app/features/certificates/presentation/bloc/certificate_bloc.dart';
import 'package:ketroy_app/features/certificates/presentation/pages/certificate_page.dart';
import 'package:ketroy_app/features/certificates/presentation/pages/sent_certificate.dart';
import 'package:ketroy_app/features/certificates/presentation/pages/tab_item.dart';
import 'package:ketroy_app/services/analytics/social_analytics_service.dart';

class CertificateTabPage extends StatelessWidget {
  const CertificateTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CertificateBloc, CertificateState>(
      listener: (context, state) {},
      builder: (context, state) {
        final url = (state.city == 'Алматы')
            ? WhatsAppContacts.almatyWhatsapp
            : (state.city == 'Астана')
                ? WhatsAppContacts.astanaWhatsapp
                : (state.city == 'Актау')
                    ? WhatsAppContacts.aqtauWhatsapp
                    : (state.city == 'Шымкент')
                        ? WhatsAppContacts.shymkentWhatsapp
                        : null;
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              // leading: CustomBackButton(),
              title: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                child: Text(
                  'Подарочные сертификат',
                  style: AppTheme.certificateTitleTextStyle
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              bottom: PreferredSize(
                  preferredSize: Size.fromHeight(40.h),
                  child: Container(
                    height: 40,
                    margin: EdgeInsets.symmetric(horizontal: 35.w),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(21),
                        color: const Color(0xFFF2F2F2)),
                    child: TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(21)),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.black,
                        tabs: const [
                          TabItem(title: 'Бумажный'),
                          TabItem(
                            title: 'Электронный',
                          ),
                        ]),
                  )),
            ),
            body: TabBarView(children: [
              Column(
                children: [
                  SizedBox(
                    height: 20.h,
                  ),
                  SizedBox(
                    height: 344.h,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 70.w,
                          top: 10.h,
                          child: Transform.rotate(
                              angle: 10 * 3.1416 / 180,
                              child: SizedBox(
                                  width: 380.w,
                                  child: Image.asset(
                                      'images/certificate-bumag.png'))),
                        ),
                        Positioned(
                          left: -53.w,
                          top: 125.h,
                          child: Transform.rotate(
                              angle: -10 * 3.1416 / 180,
                              child: SizedBox(
                                  width: 380.w,
                                  child: Image.asset(
                                      'images/certificate-bumag.png'))),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    textAlign: TextAlign.center,
                    'БУМАЖНЫЙ ПОДАРОЧНЫЙ СЕРТИФИКАТ  ',
                    style: AppTheme.certificateBigTextStyle
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 20.h,
                  ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 35.w),
                      child: Row(
                        children: [
                          Expanded(
                              child: AppButton(
                                  title: 'Заказать',
                                  onPressed: () {
                                    if (url != null) {
                                      // Трекинг клика WhatsApp со страницы сертификатов
                                      socialAnalytics.trackWhatsAppFromCertificate(
                                        city: state.city,
                                        url: url.toString(),
                                      );
                                      launchURL(url);
                                    }
                                  },
                                  backgroundColor: Colors.black)),
                        ],
                      ),
                    ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 35.w),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          width: 320.w,
                          height: 225.h,
                          'images/certificate.png',
                          fit: BoxFit.cover,
                        ),
                        const Column(
                          children: [
                            // SvgPicture.asset('images/cert-logo.svg'),
                          ],
                        )
                      ],
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    Text(
                      textAlign: TextAlign.center,
                      'ЭЛЕКТРОННЫЙ ПОДАРОЧНЫЙ СЕРТИФИКАТ  ',
                      style: AppTheme.certificateBigTextStyle
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                              title: 'Подарить ',
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const SendCertificatePage()));
                              },
                              backgroundColor: Colors.black),
                        ),
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
                              title: 'Мои карты',
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const CertificatePage()));
                              },
                              backgroundColor: Colors.white),
                        )),
                      ],
                    )
                  ],
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}
