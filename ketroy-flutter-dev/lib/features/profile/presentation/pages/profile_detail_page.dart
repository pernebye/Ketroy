import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ketroy_app/core/common/widgets/dropdown_field.dart';
import 'package:ketroy_app/core/constants/constants.dart';
import 'package:ketroy_app/core/transitions/slide_over_page_route.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:ketroy_app/features/profile/presentation/pages/city_selection_page.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:ketroy_app/services/shared_preferences_service.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart' show AppLiquidGlassSettings;
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:ketroy_app/core/common/mixins/adaptive_header_mixin.dart';

class ProfileDetailPage extends StatefulWidget {
  const ProfileDetailPage({super.key});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage>
    with SingleTickerProviderStateMixin, AdaptiveHeaderMixin {
  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _darkBg = Color(0xFF1A1F12);
  static const Color _cardBg = Color(0xFFF5F7F0);

  String? _shoeValue;
  String? _heightValue;
  String? _clothSizeValue;
  String? birthDate;
  File? selectedImage;
  String? city;
  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController cityController = TextEditingController();

  final sharedService = serviceLocator<SharedPreferencesService>();
  bool _isProcessing = false;
  final bool _hasNavigatedBack = false;
  
  // Флаг для предотвращения повторной инициализации контроллеров
  bool _controllersInitialized = false;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadDetailedUserInfo());
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    
    // Инициализация адаптивного хедера
    initAdaptiveHeader(fallbackHeightRatio: 0.18);
  }

  @override
  void dispose() {
    _animController.dispose();
    nameController.dispose();
    surnameController.dispose();
    cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SwipeBackWrapper(
        child: Scaffold(
          backgroundColor: _cardBg,
          body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state.isUpdateSuccess && !_hasNavigatedBack) {
              context.read<ProfileBloc>().add(ResetListener());
              if (mounted) Navigator.pop(context);
            }
            if (state.isUpdateFailure && !_isProcessing) {
              _isProcessing = false;
              showSnackBar(context, state.message ?? 'error');
            }
          },
          builder: (context, state) {
            if (state.isDetailedSuccess) {
              if (state.avatarImage != null) {
                selectedImage = File(state.avatarImage!);
              }
              // Инициализируем контроллеры только один раз при первой загрузке данных
              // Это предотвращает сброс пользовательского ввода при нажатии "Done" на клавиатуре iOS/Android
              if (!_controllersInitialized) {
                nameController.text = state.name ?? '';
                surnameController.text = state.surname ?? '';
                _controllersInitialized = true;
              }
              return _buildContent(state);
            }
            return const Center(child: Loader());
          },
        ),
        ),
      ),
    );
  }

  Widget _buildContent(ProfileState state) {
    // Планируем измерение хедера
    scheduleHeaderMeasurement();
    
    return Stack(
      children: [
        // Адаптивный градиентный фон
        buildAdaptiveGradient(colors: [_darkBg, _primaryGreen]),

        // Основной контент
        SafeArea(
          child: Column(
            children: [
              // Header с ключом для измерения
              KeyedSubtree(key: headerKey, child: _buildHeader()),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 16.h),
                      // Форма с профилем внутри
                      _buildFormWithProfile(state),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: LiquidGlass.withOwnLayer(
              settings: AppLiquidGlassSettings.button,
              shape: LiquidRoundedSuperellipse(borderRadius: 22.r),
              child: SizedBox(
                width: 44.w,
                height: 44.w,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              l10n.profileSettingsTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 44.w),
        ],
      ),
    );
  }

  Widget _buildFormWithProfile(ProfileState state) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Профиль секция с градиентным фоном
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 24.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryGreen.withValues(alpha: 0.08),
                  _lightGreen.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
              ),
            ),
            child: Column(
              children: [
                // Аватар
                GestureDetector(
                  onTap: () =>
                      context.read<ProfileBloc>().add(UploadProfileImage()),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 100.w,
                        height: 100.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _primaryGreen.withValues(alpha: 0.2),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryGreen.withValues(alpha: 0.15),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: (state.avatarImage == '' ||
                                  state.avatarImage == null)
                              ? Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [_primaryGreen, _lightGreen],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (state.name?.isNotEmpty == true)
                                          ? state.name!
                                              .substring(0, 1)
                                              .toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        fontSize: 36.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : state.isUploadingAvatar
                                  ? Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [_primaryGreen, _lightGreen],
                                        ),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : _buildAvatarImage(state.avatarImage!),
                        ),
                      ),
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                              colors: [_accentGreen, _lightGreen]),
                          boxShadow: [
                            BoxShadow(
                              color: _accentGreen.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16.w,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                // Имя
                Text(
                  '${state.name ?? ''} ${state.surname ?? ''}'.trim().isEmpty
                      ? AppLocalizations.of(context)!.userPlaceholder
                      : '${state.name ?? ''} ${state.surname ?? ''}'.trim(),
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: _darkBg,
                  ),
                ),
                SizedBox(height: 4.h),
                // Телефон
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    _formatPhone(state.phoneNumber),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: _primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Форма
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(l10n.sectionPersonalData),
                    SizedBox(height: 16.h),
                    _buildTextField(l10n.fieldSurname, surnameController),
                    SizedBox(height: 12.h),
                    _buildTextField(l10n.fieldName, nameController),
                    SizedBox(height: 12.h),
                    _buildDateField(state),
                    SizedBox(height: 12.h),
                    _buildCityField(state),

                    SizedBox(height: 24.h),
                    _buildSectionTitle(l10n.sectionSizes),
                    SizedBox(height: 16.h),
                    _buildDropdownField(l10n.fieldHeight, state.height, Constants.heights,
                        (v) => _heightValue = v),
                    SizedBox(height: 12.h),
                    _buildDropdownField(l10n.fieldClothingSize, state.clotherSize,
                        Constants.clothingSizes, (v) => _clothSizeValue = v),
                    SizedBox(height: 12.h),
                    _buildDropdownField(l10n.fieldShoeSize, state.shoeSize,
                        Constants.shoeSize, (v) => _shoeValue = v),

                    SizedBox(height: 32.h),
                    _buildSaveButton(state),
                    SizedBox(height: 16.h),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(String avatarImage) {
    final isNetworkImage = avatarImage.startsWith('http://') || 
                           avatarImage.startsWith('https://');
    
    if (isNetworkImage) {
      return Image.network(
        avatarImage,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryGreen, _lightGreen],
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryGreen, _lightGreen],
              ),
            ),
            child: Center(
              child: Icon(Icons.error_outline, color: Colors.white, size: 32.sp),
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(avatarImage),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryGreen, _lightGreen],
              ),
            ),
            child: Center(
              child: Icon(Icons.error_outline, color: Colors.white, size: 32.sp),
            ),
          );
        },
      );
    }
  }

  String _formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '+7 (---) ---‑--‑--';
    // Убираем всё кроме цифр
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 10) return '+7 $phone';
    // Берём последние 10 цифр
    final last10 = digits.length >= 10
        ? digits.substring(digits.length - 10)
        : digits;
    return '+7 (${last10.substring(0, 3)}) ${last10.substring(3, 6)}-${last10.substring(6, 8)}-${last10.substring(8)}';
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: _primaryGreen,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(fontSize: 16.sp),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(ProfileState state) {
    final l10n = AppLocalizations.of(context)!;
    // Дата рождения неизменяема, если уже установлена
    final bool hasBirthDate = state.birthDay != null && state.birthDay!.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.fieldBirthDate,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hasBirthDate) ...[
              SizedBox(width: 6.w),
              Icon(Icons.lock_outline, size: 14.sp, color: Colors.black38),
            ],
          ],
        ),
        SizedBox(height: 6.h),
        GestureDetector(
          onTap: hasBirthDate ? null : () => _showRussianDatePicker(state),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: hasBirthDate ? _cardBg.withValues(alpha: 0.7) : _cardBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 20.w, color: hasBirthDate ? Colors.black38 : _primaryGreen),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    birthDate ?? state.birthDay ?? AppLocalizations.of(context)!.selectDatePlaceholder,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: hasBirthDate ? Colors.black54 : Colors.black,
                    ),
                  ),
                ),
                Icon(
                  hasBirthDate ? Icons.lock_outline : Icons.chevron_right_rounded,
                  color: Colors.black38,
                  size: hasBirthDate ? 18.w : 24.w,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCityField(ProfileState state) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.fieldCity,
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 6.h),
        GestureDetector(
          onTap: () async {
            final selectedCity = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CitySelectionPage()),
            );
            if (selectedCity != null) {
              setState(() => city = selectedCity.toString());
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, size: 20.w, color: _primaryGreen),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    city ?? state.city ?? AppLocalizations.of(context)!.selectCityPlaceholder,
                    style: TextStyle(fontSize: 16.sp),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.black38),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String? selectedValue,
      dynamic options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: DropDownField(
            labelText: '',
            selectedValue: selectedValue,
            onChanged: onChanged,
            options: options,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ProfileState state) {
    return GestureDetector(
      onTap: _isProcessing || state.isLoading
          ? null
          : () {
              if (_isProcessing || _hasNavigatedBack) return;
              _isProcessing = true;
              context.read<ProfileBloc>().add(ProfileUpdateFetch(
                    height: _heightValue ?? state.height ?? '4',
                    clothingSize: _clothSizeValue ?? state.clotherSize ?? '48',
                    shoeSize: _shoeValue ?? state.shoeSize ?? '41',
                    city: city ?? state.city!,
                    name: nameController.text,
                    surname: surnameController.text,
                    birthDay: birthDate ?? state.birthDay!,
                  ));
            },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_lightGreen, _primaryGreen]),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.saveButton,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showRussianDatePicker(ProfileState state) {
    DateTime currentDate = state.birthDay != null
        ? DateTime.parse(state.birthDay!)
        : DateTime.now().subtract(const Duration(days: 365 * 18));

    int selectedDay = currentDate.day;
    int selectedMonth = currentDate.month;
    int selectedYear = currentDate.year;

    List<int> years = List.generate(
        DateTime.now().year - 1940 + 1, (index) => DateTime.now().year - index);

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
            if (selectedDay > daysInMonth) selectedDay = daysInMonth;

            return Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                l10n.cancelButton,
                                style: TextStyle(color: Colors.red, fontSize: 16.sp),
                              ),
                            ),
                            Text(
                              l10n.fieldBirthDate,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  birthDate = DateFormat('yyyy-MM-dd').format(
                                      DateTime(selectedYear, selectedMonth, selectedDay));
                                });
                                Navigator.pop(context);
                              },
                              child: Text(
                                l10n.doneButton,
                                style: TextStyle(
                                  color: _primaryGreen,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                                initialItem: selectedDay - 1),
                            itemExtent: 40.h,
                            onSelectedItemChanged: (index) {
                              setModalState(() => selectedDay = index + 1);
                            },
                            children: List.generate(daysInMonth, (index) {
                              return Center(
                                child: Text('${index + 1}',
                                    style: TextStyle(fontSize: 18.sp)),
                              );
                            }),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                                initialItem: selectedMonth - 1),
                            itemExtent: 40.h,
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                selectedMonth = index + 1;
                                int newDaysInMonth =
                                    DateTime(selectedYear, selectedMonth + 1, 0).day;
                                if (selectedDay > newDaysInMonth) {
                                  selectedDay = newDaysInMonth;
                                }
                              });
                            },
                            children: RussianMonths.months.map((month) {
                              return Center(
                                child: Text(month, style: TextStyle(fontSize: 17.sp)),
                              );
                            }).toList(),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                                initialItem: years.indexOf(selectedYear)),
                            itemExtent: 40.h,
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                selectedYear = years[index];
                                if (selectedMonth == 2) {
                                  int daysInFeb = DateTime(selectedYear, 3, 0).day;
                                  if (selectedDay > daysInFeb) {
                                    selectedDay = daysInFeb;
                                  }
                                }
                              });
                            },
                            children: years.map((year) {
                              return Center(
                                child: Text('$year', style: TextStyle(fontSize: 18.sp)),
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
}

class RussianMonths {
  static const List<String> months = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  static String getMonthName(int monthNumber) {
    if (monthNumber >= 1 && monthNumber <= 12) return months[monthNumber - 1];
    return '';
  }

  static int getMonthNumber(String monthName) => months.indexOf(monthName) + 1;
}
