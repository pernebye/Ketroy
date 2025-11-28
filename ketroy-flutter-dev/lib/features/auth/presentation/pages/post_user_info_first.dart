import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ketroy_app/core/common/entities/menu.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart';
import 'package:ketroy_app/core/common/widgets/unified_input_field.dart';
import 'package:ketroy_app/core/theme/app_pallete.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/core/common/widgets/city_bottom_sheet_picker.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ketroy_app/features/auth/presentation/pages/post_users_info_page.dart';
import 'package:ketroy_app/features/profile/presentation/pages/profile_detail_page.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:ketroy_app/services/shared_preferences_service.dart';

class PostUserInfoFirst extends StatefulWidget {
  final String name;
  final String surname;
  final String phone;
  final String code;
  final String? refCode;

  const PostUserInfoFirst(
      {super.key,
      required this.name,
      required this.surname,
      required this.phone,
      required this.code,
      this.refCode});

  static Route route({
    required String name,
    required String surname,
    required String phone,
    required String code,
    required String? deviceToken,
    String? refCode,
  }) {
    return MaterialPageRoute(
      builder: (context) => PostUserInfoFirst(
        name: name,
        surname: surname,
        phone: phone,
        code: code,
        refCode: refCode,
      ),
    );
  }

  @override
  State<PostUserInfoFirst> createState() => _PostUserInfoFirstState();
}

class _PostUserInfoFirstState extends State<PostUserInfoFirst> {
  final sharedService = serviceLocator<SharedPreferencesService>();

  List<Menu> cityNames = [];
  int counter = 1;

  String? birthDate;
  int? cityValue;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(CityNamesFetch());
  }

  void _initializeCodes(AuthState state) {
    if (cityNames.isEmpty) {
      // Используем статический список городов
      final staticCities = [
        'Астана',
        'Алматы',
        'Шымкент',
        'Актобе',
        'Караганда',
        'Тараз',
        'Атырау',
        'Павлодар',
        'Семей',
        'Усть-Каменогорск',
        'Уральск',
        'Костанай',
      ];

      // Если с бэкенда пришли города, используем их, иначе статический список
      final citiesToUse = state.cityNames.isNotEmpty
          ? state.cityNames.map((e) => e.city).toList()
          : staticCities;

      for (var cityName in citiesToUse) {
        Menu menu = Menu(
          name: cityName,
          value: counter,
          image: const SizedBox(),
        );
        cityNames.add(menu);
        counter++;
      }
    }
  }

  void _showDatePicker() {
    DateTime currentDate =
        DateTime.now().subtract(const Duration(days: 365 * 18));

    int selectedDay = currentDate.day;
    int selectedMonth = currentDate.month;
    int selectedYear = currentDate.year;

    // Генерируем годы от 1940 до текущего года
    List<int> years = List.generate(
        DateTime.now().year - 1940 + 1, (index) => DateTime.now().year - index);

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Определяем количество дней в выбранном месяце
            int daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
            if (selectedDay > daysInMonth) {
              selectedDay = daysInMonth;
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Column(
                children: [
                  // Верхняя панель с кнопками
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Отмена',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              'Дата рождения',
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  decoration: TextDecoration.none),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              birthDate = DateFormat('yyyy-MM-dd').format(
                                  DateTime(selectedYear, selectedMonth,
                                      selectedDay));
                            });
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Готово',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Date Picker с тремя колонками
                  Expanded(
                    child: Row(
                      children: [
                        // День
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: selectedDay - 1,
                            ),
                            itemExtent: 40.h,
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                selectedDay = index + 1;
                              });
                            },
                            children: List.generate(daysInMonth, (index) {
                              return Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(fontSize: 18.sp),
                                ),
                              );
                            }),
                          ),
                        ),

                        // Месяц (на русском)
                        Expanded(
                          flex: 2,
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: selectedMonth - 1,
                            ),
                            itemExtent: 40.h,
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                selectedMonth = index + 1;
                                // Проверяем, что день не превышает количество дней в новом месяце
                                int newDaysInMonth =
                                    DateTime(selectedYear, selectedMonth + 1, 0)
                                        .day;
                                if (selectedDay > newDaysInMonth) {
                                  selectedDay = newDaysInMonth;
                                }
                              });
                            },
                            children: RussianMonths.months.map((month) {
                              return Center(
                                child: Text(
                                  month,
                                  style: TextStyle(fontSize: 17.sp),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // Год
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: years.indexOf(selectedYear),
                            ),
                            itemExtent: 40.h,
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                selectedYear = years[index];
                                // Проверяем високосный год для февраля
                                if (selectedMonth == 2) {
                                  int daysInFeb =
                                      DateTime(selectedYear, 3, 0).day;
                                  if (selectedDay > daysInFeb) {
                                    selectedDay = daysInFeb;
                                  }
                                }
                              });
                            },
                            children: years.map((year) {
                              return Center(
                                child: Text(
                                  '$year',
                                  style: TextStyle(fontSize: 18.sp),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _isFormValid() {
    return birthDate != null && cityValue != null;
  }

  void _handleSave() {
    if (!_isFormValid()) {
      showSnackBar(context, 'Пожалуйста, заполните все поля');
      return;
    }
    Navigator.push(
      context,
      PostUsersInfoPage.route(
        name: widget.name,
        surname: widget.surname,
        phone: widget.phone,
        code: widget.code,
        deviceToken: null,
        cityName: cityNames.firstWhere((menu) => menu.value == cityValue).name,
        birthDate: birthDate ?? '',
      ),
    );
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
          listener: (context, state) {},
          builder: (context, state) {
            // Инициализируем города (используется статический список если с бэкенда ничего не пришло)
            _initializeCodes(state);

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
                              padding: EdgeInsets.symmetric(horizontal: 25.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 60.h),
                                  // Заголовок
                                  Text(
                                    'Еще немного',
                                    style: AppTheme.authTitleTextStyle,
                                    textAlign: TextAlign.center,
                                  ),

                                  SizedBox(height: 10.h),

                                  Text(
                                    'Пожалуйста, предоставьте актуальные данные, чтобы мы подобрали для вас идеальный стиль.',
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
                                      // Дата рождения
                                      GestureDetector(
                                        onTap: _showDatePicker,
                                        child: UnifiedInputField(
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              birthDate != null
                                                  ? DateFormat('dd.MM.yyyy')
                                                      .format(DateTime.parse(
                                                          birthDate!))
                                                  : 'Дата рождения',
                                              style: birthDate != null
                                                  ? UnifiedInputField.textStyle
                                                  : UnifiedInputField.hintStyle,
                                            ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: 14.h),

                                      // Город
                                      CityBottomSheetPicker(
                                        items: cityNames,
                                        selectedValue: cityValue,
                                        onChanged: (value) {
                                          setState(() {
                                            cityValue = value;
                                          });
                                        },
                                        hintTitle: 'Выберите город',
                                      ),

                                      SizedBox(height: 14.h),

                                      // Кнопка сохранения
                                      SizedBox(
                                        width: double.infinity,
                                        child: GlassMorphism(
                                          onPressed: _handleSave,
                                          child: Text(
                                            'Продолжить',
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
                    left: 25.w,
                    child: GestureDetector(
                      onTap: () {
                        // Просто возвращаемся на sms_page
                        // .then() в sms_page автоматически закроет sms_page и вернет на sign_up_page
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
            );
          },
        ),
      ),
    );
  }
}
