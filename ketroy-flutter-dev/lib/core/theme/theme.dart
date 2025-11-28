import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

class AppTheme {
  // Gilroy font family with fallback for Kazakh characters
  static const String fontFamily = 'Gilroy';
  
  // Fallback fonts for characters not in Gilroy (Kazakh, etc.)
  static const List<String> fontFamilyFallback = [
    'NotoSans', // Good Cyrillic Extended support including Kazakh
    'Roboto',
    'sans-serif',
  ];
  
  /// Initialize fonts - call this during app startup to ensure fallback fonts are loaded
  static Future<void> initFonts() async {
    // Preload Noto Sans for Kazakh character support
    GoogleFonts.pendingFonts([
      GoogleFonts.notoSans(),
    ]);
  }
  
  /// Helper to create TextStyle with proper fallback for Kazakh characters
  static TextStyle textStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  // Брендовые цвета Ketroy
  static const Color brandColor = Color(0xFF3C4B1B); // Тёмно-зелёный Ketroy
  static const Color brandColorLight = Color(0xFF5A6F2B); // Светлый вариант
  static const Color brandColorDark = Color(0xFF2A3512); // Тёмный вариант

  static _border([Color color = const Color.fromRGBO(52, 51, 67, 1)]) =>
      OutlineInputBorder(borderSide: BorderSide(color: color, width: 1));

  // Базовый TextTheme с Gilroy для всего приложения + fallback для казахских букв
  static TextTheme get _textTheme => const TextTheme(
        displayLarge:
            TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback, fontWeight: FontWeight.bold),
        displayMedium:
            TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback, fontWeight: FontWeight.bold),
        displaySmall:
            TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback, fontWeight: FontWeight.bold),
        headlineLarge:
            TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback, fontWeight: FontWeight.bold),
        headlineMedium:
            TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback, fontWeight: FontWeight.w500),
        headlineSmall:
            TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback, fontWeight: FontWeight.w500),
        titleLarge:
            TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback, fontWeight: FontWeight.w500),
        titleMedium:
            TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback, fontWeight: FontWeight.w500),
        titleSmall:
            TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback, fontWeight: FontWeight.w500),
        bodyLarge:
            TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback, fontWeight: FontWeight.normal),
        bodyMedium:
            TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback, fontWeight: FontWeight.normal),
        bodySmall:
            TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback, fontWeight: FontWeight.normal),
        labelLarge:
            TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback, fontWeight: FontWeight.w500),
        labelMedium:
            TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback, fontWeight: FontWeight.normal),
        labelSmall:
            TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback, fontWeight: FontWeight.normal),
      );

  static final lightThemeMode = ThemeData(
      fontFamily: fontFamily,
      textTheme: _textTheme,
      scaffoldBackgroundColor: Colors.white,
      // Брендовая цветовая схема
      primaryColor: brandColor,
      colorScheme: const ColorScheme.light(
        primary: brandColor,
        secondary: brandColorLight,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
      ),
      // Отключаем ZoomPageTransitionsBuilder, который конфликтует с liquid_glass_renderer
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      // Цвет индикаторов прогресса
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandColor,
        circularTrackColor: Color(0xFFE0E0E0),
      ),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 28.w, vertical: 15.h),
          border: _border(),
          enabledBorder: _border(),
          focusedBorder:
              _border(brandColor), // Используем брендовый цвет вместо синего
          errorBorder: _border(Colors.red),
          fillColor: Colors.white));

  //Auth TextStyle
  static final authTitleTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 22.sp,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      height: 1.2,
      letterSpacing: -0.5);
  static final authSubtitleTextStyle = TextStyle(
      fontFamily: fontFamily, fontSize: 17.sp, color: const Color(0xFFD0CFCF));
  static final authHintTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 17.sp,
      color: const Color(0xFFD0CFCF),
      height: 1.2,
      letterSpacing: 0.5);
  static final underLineWords = TextStyle(
      fontFamily: fontFamily,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFFAF3ED).withValues(alpha: 0.5),
      fontSize: 13.sp);
  static final regularText =
      TextStyle(fontFamily: fontFamily, fontSize: 17.sp, height: 1.2);
  static final haveAccount = TextStyle(
      fontFamily: fontFamily,
      fontSize: 17.sp,
      color: Colors.white,
      letterSpacing: -0.5);

  //SignUpTextStyle
  static final signUpSmallTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 17.sp,
      height: 1.2,
      letterSpacing: -0.5);

  //NewsTextStyle
  static final newsLargeTextStyle = TextStyle(
      fontFamily: fontFamily, fontSize: 22.sp, letterSpacing: 0.5, height: 1.2);
  static final newsMediumTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 15.sp,
      letterSpacing: -0.24,
      height: 1.2);

  //ShoppTextStyle
  static final shopLargeTextStyle = TextStyle(
      fontFamily: fontFamily, fontSize: 22.sp, fontWeight: FontWeight.w700);
  static final shopNormalTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 17.sp);

  //ProfileTextStyle
  static final profileLargeTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 17.sp);
  static final profileMediumTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 15.sp);
  static final profileSmallTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 13.sp);
  static final profileSmallerTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 10.sp);

  //DrawerTextStyle
  static final drawerTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 20.sp);

  //QrScreen textStyle
  static final qrScreenTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 17.sp);

  //ProfileDetail textStyle
  static final profileDetailMediumTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 17.sp);
  static final profileDetailSmallTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 13.sp);
  static final profileDetailLargeTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 20.sp);

  //Notification textStyle
  static final notificationMediumTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 17.sp);
  static final notificationLargeTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 25.sp);
  static final notificationSmallTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 15.sp);

  //feedback textStyle
  static final feedbackMediumTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 14.sp);
  static final feedbackSmallTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 10.sp);

  //Bonus TextStyle
  static final bonusTitleTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 17.sp);

  //Certificate TextStyle
  static final certificateTitleTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 17.sp);
  static final certificateBigTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 20.sp);
  static final certificateSmallTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 6.sp);
  static final certificatePriceTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 24.sp);
  static final certificateMediumTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 12.sp);

  //Button TextStyle
  static final buttonTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 17.sp,
      fontWeight: FontWeight.bold,
      color: Colors.black);

  //PartnersPage TextStyle
  static final partnersTitleTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 17.sp,
      letterSpacing: -0.24,
      height: 1.2);
  static final partnersCountTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 48.sp);

  //DiscountTextStyle
  static final discountTitleTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 17.sp);

  //GiftTextStyle
  static final giftTextStyle =
      TextStyle(fontFamily: fontFamily, fontSize: 17.sp);
  static final giftTextStyleLarge = TextStyle(
      fontFamily: fontFamily, fontSize: 37.sp, fontWeight: FontWeight.bold);

  //Banners textstyle
  static final bannersTitleTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 22.sp,
      color: Colors.white,
      fontWeight: FontWeight.bold);
  static final bannersSubtitleTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 17.sp,
      color: Colors.white,
      height: 1.2,
      letterSpacing: 0.5);

  //DialogTextStyle
  static final dialogTitleTextStyle = TextStyle(
      fontFamily: fontFamily, fontSize: 22.sp, fontWeight: FontWeight.bold);
  static final dialogRegularTextStyle = TextStyle(
      fontFamily: fontFamily, fontSize: 14.sp, letterSpacing: 0.5, height: 1.2);

  static final defaultPintheme = PinTheme(
      width: 60.w, // Увеличили с 50.w на 60.w
      height: 65.h, // Увеличили с 41.h на 65.h чтобы совпадала с другими полями
      padding: const EdgeInsets.only(top: 0, bottom: 0),
      textStyle: TextStyle(
          fontFamily: fontFamily, fontSize: 22.sp, color: Colors.black),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(13.r), // Увеличили radius с 8.r на 13.r
          border: Border.all(color: Colors.transparent)));
}
