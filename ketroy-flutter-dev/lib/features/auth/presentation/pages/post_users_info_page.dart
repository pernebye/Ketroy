import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart';
import 'package:ketroy_app/core/constants/constants.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';
import 'package:ketroy_app/core/theme/app_pallete.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/core/common/widgets/menu_bottom_sheet_picker.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:ketroy_app/main.dart' show globalDeepLinkManager, navigatorKey;
import 'package:ketroy_app/services/shared_preferences_service.dart';

class PostUsersInfoPage extends StatefulWidget {
  final String name;
  final String surname;
  final String phone;
  final String code;
  final String cityName;
  final String birthDate;

  const PostUsersInfoPage({
    super.key,
    required this.name,
    required this.surname,
    required this.phone,
    required this.code,
    required this.cityName,
    required this.birthDate,
  });

  static Route route({
    required String name,
    required String surname,
    required String phone,
    required String code,
    required String cityName,
    required String birthDate,
    required String? deviceToken,
  }) {
    return MaterialPageRoute(
      builder: (context) => PostUsersInfoPage(
        name: name,
        surname: surname,
        phone: phone,
        code: code,
        cityName: cityName,
        birthDate: birthDate,
      ),
    );
  }

  @override
  State<PostUsersInfoPage> createState() => _PostUsersInfoPageState();
}

class _PostUsersInfoPageState extends State<PostUsersInfoPage> {
  final sharedService = serviceLocator<SharedPreferencesService>();

  int counter = 1;

  int? heightValue;
  int? clothValue;
  int? shoeValue;
  String? refCode;

  @override
  void initState() {
    refCode = globalDeepLinkManager.refParameter;
    debugPrint('Ref from global: $refCode');
    super.initState();
  }

  bool _isFormValid() {
    return heightValue != null && clothValue != null && shoeValue != null;
  }

  void _handleSave() {
    if (!_isFormValid()) {
      showSnackBar(context, AppLocalizations.of(context)!.requiredField);
      return;
    }

    context.read<AuthBloc>().add(AuthSignUpWithPhone(
        name: widget.name,
        surname: widget.surname,
        phone: widget.phone,
        code: widget.code,
        birthDate: widget.birthDate,
        city: widget.cityName,
        height: Constants.heights
            .firstWhere((height) => height.value == heightValue)
            .name,
        clothingSize: Constants.clothingSizes
            .firstWhere((clothSize) => clothSize.value == clothValue)
            .name,
        shoeSize: Constants.shoeSize
            .firstWhere((shoeSize) => shoeSize.value == shoeValue)
            .name,
        promoCode: refCode));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/back_image.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.isSignUpWithDataSuccess) {
              // Переход на витрину с анимацией приветствия после регистрации
              sharedService.passed = true;
              sharedService.deviceTokenPassed = true;
              // Используем глобальный navigatorKey для надёжной навигации на витрину
              // НЕ используем NavScreen.globalKey чтобы создать свежий NavScreen
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const NavScreen(
                    initialTab: 0, // Всегда на витрину
                    showWelcomeAnimation: true, // Показываем анимацию приветствия
                  ),
                ),
                (route) => false,
              );
            } else if (state.isSignUpWithDataFailure) {
              showSnackBar(context, state.message ?? AppLocalizations.of(context)!.unknownError);
            }
          },
          builder: (context, state) {
            if (state.cityNames.isEmpty) {
              return const Loader();
            }
            return SafeArea(
                child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 17.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Заголовок
                                Text(
                                  AppLocalizations.of(context)!.almostDone,
                                  style: AppTheme.authTitleTextStyle,
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(height: 10.h),

                                Text(
                                  AppLocalizations.of(context)!.provideDataHint,
                                  style: AppTheme.regularText.copyWith(
                                    color: AppPallete.halfOpacity,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(height: 30.h),

                                // Форма
                                Column(
                                  children: [
                                    // Рост
                                    MenuBottomSheetPicker(
                                      items: Constants.heights,
                                      selectedValue: heightValue,
                                      onChanged: (value) {
                                        setState(() {
                                          heightValue = value;
                                        });
                                      },
                                      hintTitle: 'Рост',
                                    ),

                                    SizedBox(height: 14.h),

                                    // Размер одежды
                                    MenuBottomSheetPicker(
                                      items: Constants.clothingSizes,
                                      selectedValue: clothValue,
                                      onChanged: (value) {
                                        setState(() {
                                          clothValue = value;
                                        });
                                      },
                                      hintTitle: 'Размер одежды',
                                    ),

                                    SizedBox(height: 14.h),

                                    // Размер обуви
                                    MenuBottomSheetPicker(
                                      items: Constants.shoeSize,
                                      selectedValue: shoeValue,
                                      onChanged: (value) {
                                        setState(() {
                                          shoeValue = value;
                                        });
                                      },
                                      hintTitle: 'Размер обуви',
                                    ),

                                    SizedBox(
                                      height: 13.h,
                                    ),

                                    // Кнопка сохранения
                                    SizedBox(
                                      width: double.infinity,
                                      child: GlassMorphism(
                                        onPressed: _handleSave,
                                        child: Text(
                                          'Сохранить',
                                          style: TextStyle(
                                            fontSize: 17.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 50.h),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 20.h,
                  left: 17.w,
                  child: GestureDetector(
                    onTap: () {
                      // Вернуться на post_user_info_first
                      // Проверяем что можно делать pop (защита от пустого стека)
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                ),
              ],
            ));
          },
        ),
      ),
    );
  }
}
