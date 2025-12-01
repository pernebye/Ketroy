import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/entities/menu.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';
import 'package:ketroy_app/features/auth/presentation/pages/sign_up_page.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

class SelectPage extends StatelessWidget {
  SelectPage({super.key});

  final List<Menu> itemsSkud = [
    Menu(name: '+7', value: 1, image: Image.asset('images/kz.png')),
    Menu(name: '+8', value: 2, image: Image.asset('images/rus.png')),
    Menu(name: '+90', value: 3, image: Image.asset('images/tur.png')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage('images/backImage.png'),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 1.0)
                ])),
            child: Column(
              children: [
                SizedBox(
                  height: 280.h,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('images/logoK.png')
                    // SvgPicture.asset('images/logoK.svg'),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 34.w),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 20.h,
                      ),
                      Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Column(
                          children: [
                            Text(
                              textAlign: TextAlign.center,
                              l10n?.startUsing ?? 'How would you like to\nstart using the app?',
                              style: const TextStyle(fontSize: 20, color: Colors.white),
                            ),
                            SizedBox(height: 20.h),
                            GlassMorphism(
                              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                              width: double.infinity,
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SignUpPage(codes: itemsSkud)));
                              },
                              child: Text(
                                textAlign: TextAlign.center,
                                l10n?.register ?? 'Register',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                    height: 1.2),
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            GlassMorphism(
                              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                              width: double.infinity,
                              onPressed: () {
                                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (context) => NavScreen(
                                              key: NavScreen.globalKey,
                                              withToken: false,
                                              initialTab: 0,
                                            )),
                                    (route) => route.isFirst);
                              },
                              child: Text(
                                textAlign: TextAlign.center,
                                l10n?.browseAsGuest ?? 'Browse as Guest',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                    height: 1.2),
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                      // InkWell(
                      //   onTap: () {

                      //   },
                      //   child: Container(
                      //     padding: EdgeInsets.symmetric(
                      //         vertical: 19.5.h, horizontal: 36.5.w),
                      //     decoration: BoxDecoration(
                      //         color: Colors.white,
                      //         borderRadius: BorderRadius.circular(13.r)),
                      //     child: Text(
                      //       textAlign: TextAlign.center,
                      //       'Хочу ознакомиться с приложением без регистрации.',
                      //       style: TextStyle(color: Colors.black),
                      //     ),
                      //   ),
                      // ),
                      const Row()
                    ],
                  ),
                )
              ],
            ),
          )),
    );
  }
}
