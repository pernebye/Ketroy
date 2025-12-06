import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ketroy_app/features/auth/presentation/pages/post_user_info_first.dart';
import 'package:ketroy_app/features/auth/presentation/viewModel/view_model.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:ketroy_app/main.dart' show navigatorKey;
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';
import 'package:ketroy_app/services/shared_preferences_service.dart';
import 'package:ketroy_app/core/common/widgets/promo_code_success_dialog.dart';
import 'package:ketroy_app/core/common/widgets/top_toast.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

class SmsPage extends StatelessWidget {
  const SmsPage(
      {super.key,
      required this.code,
      required this.phoneNumber,
      required this.routeFrom,
      this.name,
      this.surname,
      this.refCode});

  final String code;
  final String phoneNumber;
  final String routeFrom;
  final String? name;
  final String? surname;
  final String? refCode;

  @override
  Widget build(BuildContext context) {
    // final vm = context.watch<SignUpViewModel>();
    // print('name is ${vm.name}');
    return ChangeNotifierProvider(
      create: (context) => SmsPageViewModel()..startTimer(),
      child: SmsBody(
        routeFrom: routeFrom,
        phoneNumber: phoneNumber,
        code: code,
        name: name,
        surname: surname,
      ),
    );
  }
}

class SmsBody extends StatefulWidget {
  const SmsBody(
      {super.key,
      required this.routeFrom,
      required this.phoneNumber,
      required this.code,
      this.name,
      this.surname,
      this.refCode});

  final String routeFrom;
  final String phoneNumber;
  final String code;
  final String? name;
  final String? surname;
  final String? refCode;

  @override
  State<SmsBody> createState() => _SmsBodyState();
}

class _SmsBodyState extends State<SmsBody> {
  final sharedService = serviceLocator<SharedPreferencesService>();

  final TextEditingController smsCodeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Флаг для предотвращения множественных навигаций
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // Сбрасываем состояние авторизации при входе на страницу
    // Это исправляет баг с зависшим состоянием ошибки после 401
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthResetState());
      }
    });
  }

  @override
  void dispose() {
    smsCodeController.dispose();
    super.dispose();
  }

  void _onContinuePressed() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (smsCodeController.text.length != 5) {
      showSnackBar(context, AppLocalizations.of(context)!.enterCode);
      return;
    }

    context.read<AuthBloc>().add(
          AuthSmsSend(
            code: widget.code,
            phone: widget.phoneNumber,
            sms: smsCodeController.text,
          ),
        );
  }

  void _resendCode(SmsPageViewModel vm) {
    setState(() {
      wrongPassword = false;
    });
    smsCodeController.clear(); // Очищаем поле ввода
    context.read<AuthBloc>().add(
          AuthSendVerifyCode(
            phone: widget.phoneNumber,
            code: widget.code,
          ),
        );
    vm.startTimer();
  }

  bool wrongPassword = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SmsPageViewModel>();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('images/back_image.jpg'), fit: BoxFit.cover)),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.isFailure) {
              wrongPassword = true;
              showSnackBar(context, state.message ?? AppLocalizations.of(context)!.unknownError);
            } else if (state.isSuccess) {
              wrongPassword = false;
              _handleSuccessState(state);
            }
          },
          builder: (context, state) {
            if (state.isVerifyLoading) {
              return SizedBox(
                height: MediaQuery.of(context).size.height,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Loader(),
                  ],
                ),
              );
            }
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top,
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 35.w),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 20.h,
                          ),
                          Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 10.h),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 24.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 180.h,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.enterCode,
                                style: AppTheme.authTitleTextStyle,
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 10.h,
                          ),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: AppTheme.authHintTextStyle.copyWith(
                                  color: const Color(0x80FFFFFF),
                                  fontSize: 17.sp),
                              children: [
                                TextSpan(
                                  text:
                                      '${AppLocalizations.of(context)!.smsSent} ',
                                ),
                                TextSpan(
                                  text: '+7${widget.phoneNumber}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 20.h,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Pinput(
                                  controller: smsCodeController,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  length: 5,
                                  defaultPinTheme: AppTheme.defaultPintheme,
                                  onCompleted: (value) {
                                    // Автоматически отправляем при вводе всех цифр
                                    Future.delayed(
                                        const Duration(milliseconds: 300), () {
                                      if (mounted) {
                                        _onContinuePressed();
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 13.h,
                          ),
                          Row(
                            children: [
                              Expanded(
                                  child: GlassMorphism(
                                onPressed: _onContinuePressed,
                                child: Text(
                                  AppLocalizations.of(context)!.proceed,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.1,
                                      height: 1.2),
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                ),
                              )),
                            ],
                          ),
                          SizedBox(
                            height: 20.h,
                          ),
                          if (wrongPassword)
                            Column(
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.wrongCode,
                                  style: TextStyle(
                                    color: const Color(0xFFFF3B30),
                                    fontSize: 17.sp,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(
                                  height: 5.h,
                                )
                              ],
                            ),
                          if (vm.seconds == 0)
                            InkWell(
                              onTap: () {
                                _resendCode(vm);
                              },
                              child: Text(AppLocalizations.of(context)!.sendCodeAgain,
                                  style: AppTheme.regularText
                                      .copyWith(color: Colors.white)),
                            )
                          else
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${AppLocalizations.of(context)!.sendCodeAgain} ${AppLocalizations.of(context)!.through} ',
                                    style: AppTheme.regularText,
                                  ),
                                  TextSpan(
                                    text: vm.seconds.toString(),
                                    style: AppTheme.regularText
                                        .copyWith(fontWeight: FontWeight.w500),
                                  )
                                ],
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleSuccessState(AuthState state) async {
    // Предотвращаем множественные навигации
    if (_isNavigating) return;

    if (state.authAnswerUserInfo?.user != null) {
      // Пользователь уже зарегистрирован - переходим на витрину с красивой анимацией
      sharedService.passed = true;
      _isNavigating = true;

      try {
        // Дополнительная проверка что данные действительно сохранились
        final isLoggedIn = await UserDataManager.isUserLoggedIn();

        if (isLoggedIn) {
          if (mounted) {
            // Сохраняем данные о промокоде до навигации
            final appliedPromoCode = state.appliedPromoCode;
            final promoCodeAppliedSuccessfully = state.promoCodeAppliedSuccessfully;
            
            // Используем addPostFrameCallback для безопасной навигации
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Используем глобальный navigatorKey для надёжной навигации на витрину
              // Это гарантирует переход на главный экран независимо от вложенных Navigator'ов
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
              
              // ✅ Показываем диалог успешного применения промокода если он был применен
              if (promoCodeAppliedSuccessfully == true &&
                  appliedPromoCode != null &&
                  appliedPromoCode.isNotEmpty) {
                // Показываем диалог с небольшой задержкой после навигации
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (navigatorKey.currentContext != null) {
                    PromoCodeSuccessDialog.show(
                      navigatorKey.currentContext!,
                      promoCode: appliedPromoCode,
                    );
                  }
                });
              } else if (state.promoCodeAlreadyUsed == true) {
                // ✅ Показываем тост что промокод уже был использован ранее
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (navigatorKey.currentContext != null) {
                    final l10n = AppLocalizations.of(navigatorKey.currentContext!);
                    TopToast.showWarning(
                      navigatorKey.currentContext!,
                      title: l10n?.promoCodeAlreadyUsedTitle ?? 'Промокод уже использован',
                      message: l10n?.promoCodeAlreadyUsedMessage ?? 'Вы уже применяли реферальный промокод ранее. Повторное использование невозможно.',
                    );
                  }
                });
              }
            });
          }
        } else {
          _isNavigating = false;
          if (mounted) {
            // Если по какой-то причине не сохранилось, показываем ошибку
            showSnackBar(
                context, AppLocalizations.of(context)!.dataLoadError);
          }
        }
      } catch (e) {
        _isNavigating = false;
        if (mounted) {
          showSnackBar(context, AppLocalizations.of(context)!.unknownError);
        }
      }
    } else if (widget.routeFrom == 'reg') {
      if (mounted && !_isNavigating) {
        _isNavigating = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.push(
              context,
              PostUserInfoFirst.route(
                  name: widget.name ?? '',
                  surname: widget.surname ?? '',
                  phone: widget.phoneNumber,
                  code: widget.code,
                  deviceToken: null,
                  refCode: widget.refCode),
            ).then((_) {
              _isNavigating = false;
              if (!mounted) {
                return;
              }
              // После возврата с post_user_info_first или при нажатии назад,
              // передаем верифицированный номер назад на sign_up_page
              // Проверяем что Navigator ещё существует и можно делать pop
              // (после успешной регистрации pushAndRemoveUntil удаляет все routes)
              if (Navigator.canPop(context)) {
                Navigator.pop(context, widget.phoneNumber);
              }
            });
          }
        });
      }
    } else {
      // Пользователь не зарегистрирован
      if (mounted && !_isNavigating) {
        showSnackBar(
            context, AppLocalizations.of(context)!.userNotFound);
        _isNavigating = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pop(context);
          }
          _isNavigating = false;
        });
      }
    }
  }
}
