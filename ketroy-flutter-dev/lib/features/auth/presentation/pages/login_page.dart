import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/entities/menu.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart';
import 'package:ketroy_app/core/common/widgets/bottom_sheet_picker.dart'
    show CountryCodeBottomSheetPicker;
import 'package:ketroy_app/core/common/widgets/unified_input_field.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ketroy_app/features/auth/presentation/pages/sign_up_page.dart';
import 'package:ketroy_app/features/auth/presentation/pages/sms_page.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static Route route() {
    return MaterialPageRoute(builder: (context) {
      return const LoginPage();
    });
  }

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final List<Menu> itemsSkud = [
    Menu(name: '+7', value: 1, image: Image.asset('images/kz.png')),
    Menu(name: '+8', value: 2, image: Image.asset('images/rus.png')),
    Menu(name: '+90', value: 3, image: Image.asset('images/tur.png')),
  ];

  int selectedValue = 1;
  int counter = 1;
  bool pressed = false;
  final maskFormatter = MaskTextInputFormatter(mask: '(###) ###-##-##');
  String phoneNumberFormat = '';

  final TextEditingController controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  void _onLoginPressed() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    phoneNumberFormat = controller.text.replaceAll(RegExp(r'\D'), '');

    if (phoneNumberFormat.isEmpty) {
      showSnackBar(context, 'Введите номер телефона');
      return;
    }

    if (phoneNumberFormat.length < 10) {
      showSnackBar(context, 'Номер телефона слишком короткий');
      return;
    }

    setState(() {
      pressed = true;
    });

    final selectedCode = itemsSkud.firstWhere(
      (menu) => menu.value == selectedValue,
      orElse: () => itemsSkud.first,
    );

    // Используем AuthLoginSendCode для проверки существования пользователя
    context.read<AuthBloc>().add(
          AuthLoginSendCode(
            phone: phoneNumberFormat,
            code: selectedCode.name,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('images/back_image.jpg'), fit: BoxFit.fill)),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (BuildContext context, AuthState state) {
            if (state.isVerifyFailure) {
              setState(() {
                pressed = false;
              });
              showSnackBar(context, state.message ?? 'Ошибка отправки кода');
            } else if (state.isVerifySuccess && pressed) {
              pressed = false;
              final selectedCode = itemsSkud.firstWhere(
                (menu) => menu.value == selectedValue,
                orElse: () => itemsSkud.first,
              );

              // Проверяем существует ли пользователь
              if (state.userExists == false) {
                // Пользователь не найден - перенаправляем на регистрацию
                showSnackBar(context,
                    'Аккаунт не найден. Пожалуйста, зарегистрируйтесь.');
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SignUpPage(
                              codes: itemsSkud,
                              initialPhone: phoneNumberFormat,
                              initialCountryCode: selectedValue,
                            )));
              } else {
                // Пользователь существует - переходим на ввод SMS кода
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SmsPage(
                              code: selectedCode.name,
                              phoneNumber: phoneNumberFormat,
                              routeFrom: 'login',
                            )));
              }
            }
          },
          builder: (BuildContext context, AuthState state) {
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
                    child: Column(
                      children: [
                        SizedBox(
                          height: 163.h,
                        ),
                        // Логотип
                        Image.asset('images/logoK.png'),
                        SizedBox(
                          height: 11.h,
                        ),
                        Expanded(
                          flex: 3,
                          child: Padding(
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
                                  'Войти в клуб привилегий',
                                  style: AppTheme.authSubtitleTextStyle,
                                ),
                                SizedBox(
                                  height: 20.h,
                                ),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 110.w,
                                      child: CountryCodeBottomSheetPicker(
                                        items: itemsSkud,
                                        selectedValue: selectedValue,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedValue = value ?? 0;
                                          });
                                        },
                                        hintTitle: itemsSkud[0].name,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 6.w,
                                    ),
                                    Expanded(
                                        flex: 9,
                                        child: UnifiedInputField(
                                          child: TextFormField(
                                            controller: controller,
                                            textAlignVertical:
                                                TextAlignVertical.center,
                                            minLines: 1,
                                            maxLines: 1,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [maskFormatter],
                                            style: UnifiedInputField.textStyle,
                                            decoration: InputDecoration(
                                              hintText: '(777) 777-77-77',
                                              hintStyle:
                                                  UnifiedInputField.hintStyle,
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.only(bottom: 6.h),
                                              isDense: true,
                                              isCollapsed: true,
                                            ),
                                          ),
                                        ))
                                  ],
                                ),
                                SizedBox(
                                  height: 21.h,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GlassMorphism(
                                        child: Text(
                                          textAlign: TextAlign.center,
                                          'Войти в закрытый клуб',
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
                                        onPressed: () {
                                          pressed ? null : _onLoginPressed();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 20.h,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'У вас нет аккаунта?',
                                      style: AppTheme.haveAccount,
                                    ),
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: GestureDetector(
                                          onTap: () {
                                            // Navigator.pushAndRemoveUntil(
                                            //     context,
                                            //     SignUpPage.route(codes: codes),
                                            //     (route) => false);
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        SignUpPage(
                                                            codes: itemsSkud)));
                                          },
                                          child: Text(
                                            ' Зарегистроваться',
                                            style: AppTheme.haveAccount
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        )
                      ],
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
}
