import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/entities/menu.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart';
import 'package:ketroy_app/core/common/widgets/unified_input_field.dart';
import 'package:ketroy_app/core/common/widgets/bottom_sheet_picker.dart' show CountryCodeBottomSheetPicker;
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ketroy_app/features/auth/presentation/pages/login_page.dart';
import 'package:ketroy_app/features/auth/presentation/pages/sms_page.dart';
import 'package:ketroy_app/features/auth/presentation/pages/post_user_info_first.dart';
import 'package:ketroy_app/services/shared_preferences_service.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class SignUpPage extends StatefulWidget {
  final List<Menu> codes;
  final String? initialPhone;
  final int? initialCountryCode;
  
  const SignUpPage({
    super.key, 
    required this.codes,
    this.initialPhone,
    this.initialCountryCode,
  });

  static Route route({required List<Menu> codes}) {
    return MaterialPageRoute(builder: (context) {
      return SignUpPage(
        codes: codes,
      );
    });
  }

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final sharedService = serviceLocator<SharedPreferencesService>();
  final userNameController = TextEditingController();
  final userSurnameController = TextEditingController();
  final phoneController = TextEditingController();
  String? refCode;
  bool isPhoneVerified = false;
  String? _currentSessionVerifiedPhone; // Верификация только для текущей сессии
  final List<Menu> itemsSkud = [
    Menu(name: '+7', value: 1, image: Image.asset('images/kz.png')),
    Menu(name: '+8', value: 2, image: Image.asset('images/rus.png')),
    Menu(name: '+90', value: 3, image: Image.asset('images/tur.png')),
  ];
  int selectedValue = 1;
  final maskFormatter = MaskTextInputFormatter(mask: '(###) ###-##-##');
  String phoneNumberFormat = '';

  @override
  void initState() {
    super.initState();
    phoneController.addListener(_onPhoneChanged);
    _loadPhoneVerificationStatus();
    
    // Сбрасываем состояние авторизации при входе на страницу
    // Это исправляет баг с зависшим состоянием ошибки после 401
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthResetState());
      }
    });
    
    // Инициализация начальных значений если переданы
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      // Форматируем номер для маски (###) ###-##-##
      final phone = widget.initialPhone!;
      if (phone.length >= 10) {
        final formatted = '(${phone.substring(0, 3)}) ${phone.substring(3, 6)}-${phone.substring(6, 8)}-${phone.substring(8)}';
        phoneController.text = formatted;
        maskFormatter.formatEditUpdate(
          const TextEditingValue(text: ''),
          TextEditingValue(text: formatted),
        );
      }
    }
    if (widget.initialCountryCode != null) {
      selectedValue = widget.initialCountryCode!;
    }
  }

  Future<void> _loadPhoneVerificationStatus() async {
    // Верификация хранится только в текущей сессии, не в SharedPreferences
    // При перезаходе в приложение верификация будет сброшена
  }

  void _onPhoneChanged() {
    // Проверяем если текущий номер совпадает с верифицированным в текущей сессии
    final currentPhone = phoneController.text.replaceAll(RegExp(r'\D'), '');
    
    if (_currentSessionVerifiedPhone != null && _currentSessionVerifiedPhone == currentPhone) {
      // Номер совпадает с верифицированным в этой сессии
      if (!isPhoneVerified) {
        setState(() {
          isPhoneVerified = true;
        });
      }
    } else {
      // Номер не совпадает или сессия сброшена
      if (isPhoneVerified) {
        setState(() {
          isPhoneVerified = false;
        });
      }
    }
  }

  void _checkVerificationStatus() {
    // Проверяем если номер верифицирован в текущей сессии при возврате
    final currentPhone = phoneController.text.replaceAll(RegExp(r'\D'), '');
    
    if (_currentSessionVerifiedPhone != null && 
        _currentSessionVerifiedPhone == currentPhone && 
        !isPhoneVerified) {
      setState(() {
        isPhoneVerified = true;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    userNameController.dispose();
    userSurnameController.dispose();
    phoneController.removeListener(_onPhoneChanged);
    phoneController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Проверяем верификацию при каждой перестройке страницы (например при возврате)
    _checkVerificationStatus();
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('images/back_image.jpg'), fit: BoxFit.cover)),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.isFailure) {
              showSnackBar(context, state.message ?? 'fail');
            }
            if (state.isVerifyFailure) {
              showSnackBar(context, state.message ?? 'Ошибка при отправке кода');
            }
            if (state.isVerifySuccess) {
              // Галочка будет установлена только после проверки кода на SMS странице
              // context.read<AuthBloc>().add(AuthSendVerifyCode(
              //     phone: phoneNumberFormat,
              //     code: itemsSkud
              //         .firstWhere((menu) => menu.value == selectedValue)
              //         .name));
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SmsPage(
                            code: widget.codes
                                .firstWhere(
                                    (menu) => menu.value == selectedValue)
                                .name,
                            phoneNumber: phoneNumberFormat,
                            routeFrom: 'reg',
                            name: userNameController.text,
                            surname: userSurnameController.text,
                            refCode: refCode,
                          ))).then((result) {
                // Если вернулся верифицированный номер, устанавливаем флаг
                if (result != null && result is String) {
                  setState(() {
                    _currentSessionVerifiedPhone = result;
                    isPhoneVerified = true;
                  });
                }
              });
            }
            // if (state.isVerifySuccess) {
            //   Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //           builder: (context) => SmsPage(
            //                 code: itemsSkud
            //                     .firstWhere((menu) => menu.value == selectedValue)
            //                     .name,
            //                 phoneNumber: phoneNumberFormat,
            //                 routeFrom: 'reg',
            //               )));
            // }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ), // Добавляет отступ снизу равный высоте клавиатуры,
              child: Column(
                children: [
                  SizedBox(
                    height: 123.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('images/logoK.png'),
                    ],
                  ),
                  SizedBox(
                    height: 40.h,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 34.w),
                    child: Column(
                      children: [
                        Text(
                          'Добро пожаловать!',
                          style: AppTheme.authTitleTextStyle,
                        ),
                        SizedBox(
                          height: 10.h,
                        ),
                        Text(
                          textAlign: TextAlign.center,
                          'Войдите в закрытый клуб ценителей — регистрация откроет доступ к лучшему.',
                          style: AppTheme.signUpSmallTextStyle
                              .copyWith(color: const Color(0xFFD0CFCF)),
                        ),
                        SizedBox(
                          height: 20.h,
                        ),
                        UnifiedInputField(
                          child: TextFormField(
                            controller: userNameController,
                            textAlignVertical: TextAlignVertical.center,
                            minLines: 1,
                            maxLines: 1,
                            style: UnifiedInputField.textStyle,
                            decoration: InputDecoration(
                              hintText: 'Имя',
                              hintStyle: UnifiedInputField.hintStyle,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.only(bottom: 6.h),
                              isDense: true,
                              isCollapsed: true,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 13.h,
                        ),
                        UnifiedInputField(
                          child: TextFormField(
                            controller: userSurnameController,
                            textAlignVertical: TextAlignVertical.center,
                            minLines: 1,
                            maxLines: 1,
                            style: UnifiedInputField.textStyle,
                            decoration: InputDecoration(
                              hintText: 'Фамилия',
                              hintStyle: UnifiedInputField.hintStyle,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.only(bottom: 6.h),
                              isDense: true,
                              isCollapsed: true,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 13.h,
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: 110.w,
                              child: CountryCodeBottomSheetPicker(
                                items: widget.codes,
                                selectedValue: selectedValue,
                                onChanged: (value) {
                                  setState(() {
                                    selectedValue = value ?? 0;
                                  });
                                },
                                hintTitle: widget.codes[0].name,
                              ),
                            ),
                            SizedBox(
                              width: 6.w,
                            ),
                            Expanded(
                                flex: 9,
                                child: UnifiedInputField(
                                  child: TextFormField(
                                    controller: phoneController,
                                    textAlignVertical: TextAlignVertical.center,
                                    minLines: 1,
                                    maxLines: 1,
                                    inputFormatters: [maskFormatter],
                                    keyboardType: TextInputType.phone,
                                    style: UnifiedInputField.textStyle,
                                    decoration: InputDecoration(
                                      hintText: '(777) 777-77-77',
                                      hintStyle: UnifiedInputField.hintStyle,
                                      suffixIcon: isPhoneVerified
                                          ? Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 20.sp,
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.only(bottom: 6.h),
                                      isDense: true,
                                      isCollapsed: true,
                                    ),
                                  ),
                                ))
                          ],
                        ),
                        SizedBox(
                          height: 13.h,
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: GlassMorphism(
                              onPressed: state.isVerifyLoading ? null : () {
                                // Валидация имени и фамилии
                                if (userNameController.text.trim().isEmpty) {
                                  showSnackBar(context, 'Пожалуйста, введите имя');
                                  return;
                                }
                                if (userSurnameController.text.trim().isEmpty) {
                                  showSnackBar(context, 'Пожалуйста, введите фамилию');
                                  return;
                                }
                                if (phoneController.text.trim().isEmpty) {
                                  showSnackBar(context, 'Пожалуйста, введите номер телефона');
                                  return;
                                }
                                
                                phoneNumberFormat = phoneController.text
                                    .replaceAll(RegExp(r'\D'), '');
                                
                                // Валидация формата номера телефона (должно быть минимум 10 цифр)
                                if (phoneNumberFormat.length < 10) {
                                  showSnackBar(context, 'Пожалуйста, введите полный номер телефона');
                                  return;
                                }

                                // Если номер уже верифицирован, переходим сразу на post_user_info_first
                                if (isPhoneVerified) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PostUserInfoFirst(
                                        name: userNameController.text,
                                        surname: userSurnameController.text,
                                        phone: phoneNumberFormat,
                                        code: widget.codes
                                            .firstWhere((menu) =>
                                                menu.value == selectedValue)
                                            .name,
                                        refCode: refCode,
                                      ),
                                    ),
                                  );
                                } else {
                                  // Если не верифицирован, отправляем код SMS
                                  context.read<AuthBloc>().add(AuthSendVerifyCode(
                                      phone: phoneNumberFormat,
                                      code: widget.codes
                                          .firstWhere((menu) =>
                                              menu.value == selectedValue)
                                          .name));
                                }
                              },
                              child: Text(
                                state.isVerifyLoading ? 'Отправка кода...' : 'Зарегистрироваться',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17.sp,
                                    color: Colors.white,
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
                          height: 13.h,
                        ),
                        RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                    text:
                                        'Нажав "ЗАРЕГИСТРИРОВАТЬСЯ", вы соглашаетесь c ',
                                    style: TextStyle(
                                        fontSize: 13.sp,
                                        color: const Color(0xFFFAF3ED)
                                            .withValues(alpha: 0.5))),
                                TextSpan(
                                    text: 'Условиями использования',
                                    style: AppTheme.underLineWords),
                                TextSpan(
                                    text: ' и ',
                                    style: TextStyle(
                                        height: 1.2,
                                        fontSize: 13.sp,
                                        color: const Color(0xFFFAF3ED)
                                            .withValues(alpha: 0.5))),
                                TextSpan(
                                    text: 'Политикой конфиденциальности',
                                    style: AppTheme.underLineWords)
                              ],
                            )),
                        SizedBox(
                          height: 13.h,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Уже есть аккаунт?',
                              style: AppTheme.haveAccount,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context, rootNavigator: true)
                                    .pushAndRemoveUntil(
                                        LoginPage.route(),
                                        (route) => route.isFirst);
                              },
                              child: Text(
                                ' Войти',
                                style: AppTheme.haveAccount
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}