import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/transitions/slide_over_page_route.dart';
import 'package:ketroy_app/core/util/show_snackbar.dart';
import 'package:ketroy_app/features/discount/presentation/bloc/discount_bloc.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:ketroy_app/services/deep_link/create_dynamic_link.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart' show LiquidGlassButton;
import 'package:ketroy_app/core/common/mixins/adaptive_header_mixin.dart';

class DiscountPage extends StatefulWidget {
  const DiscountPage({super.key});

  @override
  State<DiscountPage> createState() => _DiscountPageState();
}

class _DiscountPageState extends State<DiscountPage>
    with SingleTickerProviderStateMixin, AdaptiveHeaderMixin {
  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _darkBg = Color(0xFF1A1F12);
  static const Color _cardBg = Color(0xFFF5F7F0);

  final TextEditingController codeController = TextEditingController();
  final TextEditingController friendCode = TextEditingController();

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    
    // Загружаем информацию о реферальной программе
    context.read<DiscountBloc>().add(LoadReferralInfo());
    
    // Инициализация адаптивного хедера
    initAdaptiveHeader(fallbackHeightRatio: 0.25);
  }

  @override
  void dispose() {
    _animController.dispose();
    codeController.dispose();
    friendCode.dispose();
    super.dispose();
  }

  void _copy(BuildContext context, AppLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: codeController.text));
    showSnackBar(context, l10n.promocodeCopied);
  }

  Future<void> _sharePromo(String promocode, AppLocalizations l10n) async {
    try {
      // Используем новый сервис шаринга с собственным доменом
      await KetroyShareService.shareReferralLink(
        referralCode: promocode,
        context: context,
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l10n.error}: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('❌ Share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SwipeBackWrapper(
        child: Scaffold(
          backgroundColor: _cardBg,
          body: BlocConsumer<DiscountBloc, DiscountState>(
            listenWhen: (previous, current) {
              // Слушаем только когда статус изменился с не-success/failure на success/failure
              return previous.status != current.status;
            },
            listener: (context, state) {
              if (state.isSuccess) {
                _showSuccessDialog(context, state, l10n);
                // Сбрасываем статус после показа диалога
                context.read<DiscountBloc>().add(ResetStatus());
              } else if (state.isFailure) {
                _showErrorDialog(context, state, l10n);
                // Сбрасываем статус после показа диалога
                context.read<DiscountBloc>().add(ResetStatus());
              }
            },
            builder: (context, state) {
              if (state.promoCode != null) {
                codeController.text = state.promoCode!;
              } else if (codeController.text.isEmpty) {
                codeController.text = l10n.yourPromocode;
              }
              return _buildContent(state, l10n);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(DiscountState state, AppLocalizations l10n) {
    // Планируем измерение хедера
    scheduleHeaderMeasurement();
    
    return Stack(
      children: [
        // Адаптивный градиентный header
        buildAdaptiveGradient(colors: [_darkBg, _primaryGreen]),

        // Контент
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                KeyedSubtree(key: headerKey, child: _buildHeader(l10n)),
                SizedBox(height: 24.h),
                _buildShareSection(state, l10n),
                SizedBox(height: 20.h),
                _buildFriendCodeSection(state, l10n),
                SizedBox(height: 20.h),
                _buildConditionsSection(state, l10n),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          LiquidGlassButton(
            onTap: () => Navigator.pop(context),
            width: 44.w,
            height: 44.w,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  l10n.giveDiscount,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share_rounded, size: 16.w, color: _accentGreen),
                    SizedBox(width: 6.w),
                    Text(
                      l10n.shareWithFriends,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 44.w),
        ],
      ),
    );
  }

  Widget _buildShareSection(DiscountState state, AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _animController.value)),
          child: Opacity(opacity: _animController.value, child: child),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: _accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: _primaryGreen,
                    size: 24.w,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.yourPromocode,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        l10n.shareAndGetBonuses,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Промокод
            GestureDetector(
              onTap: () => _copy(context, l10n),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _primaryGreen.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      codeController.text,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: _primaryGreen,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Icon(Icons.copy_rounded, size: 20.w, color: _primaryGreen),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Динамическое описание из настроек
            _buildShareDescription(state),

            SizedBox(height: 20.h),

            // Кнопка поделиться
            GestureDetector(
              onTap: () async {
                _copy(context, l10n);
                await _sharePromo(codeController.text, l10n);
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_lightGreen, _primaryGreen]),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share_rounded, color: Colors.white, size: 20.w),
                    SizedBox(width: 10.w),
                    Text(
                      l10n.share,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCodeSection(DiscountState state, AppLocalizations l10n) {
    final hasUsedPromoCode = state.referralInfo?.hasUsedPromoCode ?? false;
    
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final value = Curves.easeOut.transform(
          ((_animController.value - 0.2) / 0.8).clamp(0.0, 1.0),
        );
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: hasUsedPromoCode 
                        ? _accentGreen.withValues(alpha: 0.15)
                        : _primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    hasUsedPromoCode 
                        ? Icons.check_circle_outline_rounded
                        : Icons.person_add_outlined,
                    color: hasUsedPromoCode ? _accentGreen : _primaryGreen,
                    size: 24.w,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.friendPromocode,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      hasUsedPromoCode
                          ? Text(
                              'Промокод уже применён',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: _accentGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : _buildEnterAndGetDiscountText(state),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Если уже применён промокод - показываем сообщение
            if (hasUsedPromoCode) ...[
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: _accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _accentGreen.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: _primaryGreen,
                      size: 22.w,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Вы уже применили промокод друга и получили персональную скидку. Повторное применение недоступно.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Поле ввода
              Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: TextField(
                  controller: friendCode,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: l10n.enterFriendPromocode,
                    hintStyle: const TextStyle(
                      color: Colors.black38,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 16.h,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Динамическое описание для друга
              _buildFriendDescription(state),

              SizedBox(height: 20.h),

              // Кнопка применить
              GestureDetector(
                onTap: () {
                  if (friendCode.text.isNotEmpty) {
                    context
                        .read<DiscountBloc>()
                        .add(PostPromoCodeFetch(promoCode: friendCode.text));
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Text(
                      l10n.apply,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Секция с условиями акции
  Widget _buildConditionsSection(DiscountState state, AppLocalizations l10n) {
    final info = state.referralInfo;
    final threshold = info?.referrerHighDiscountThreshold ?? 30;
    
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final value = Curves.easeOut.transform(
          ((_animController.value - 0.15) / 0.85).clamp(0.0, 1.0),
        );
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: _accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: _primaryGreen,
                    size: 24.w,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Подробные условия',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Как работает программа',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                if (info != null && info.totalReferred > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: _accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '${info.totalReferred} ${_getPluralFriends(info.totalReferred)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: _primaryGreen,
                      ),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 24.h),
            
            // Что получит друг
            _buildConditionBlock(
              icon: Icons.person_add_rounded,
              iconColor: Colors.blue,
              title: 'Ваш друг получит',
              items: [
                _ConditionItem(
                  icon: Icons.percent_rounded,
                  text: 'Персональную скидку ${info?.newUserDiscountPercent ?? 10}% на все покупки',
                ),
                if ((info?.newUserBonusPercent ?? 0) > 0)
                  _ConditionItem(
                    icon: Icons.stars_rounded,
                    text: '${info?.newUserBonusPercent ?? 5}% бонусов с первых ${info?.newUserBonusPurchases ?? 1} ${_getPluralPurchases(info?.newUserBonusPurchases ?? 1)}',
                  ),
              ],
            ),
            
            _buildDivider(),
            
            // Что получите вы (стандартные условия)
            _buildConditionBlock(
              icon: Icons.card_giftcard_rounded,
              iconColor: _accentGreen,
              title: 'Вы получите',
              subtitle: 'при скидке до $threshold%',
              items: [
                _ConditionItem(
                  icon: Icons.stars_rounded,
                  text: '${info?.referrerBonusPercent ?? 2}% бонусов с первых ${info?.referrerMaxPurchases ?? 3} ${_getPluralPurchases(info?.referrerMaxPurchases ?? 3)} друга',
                ),
              ],
            ),
            
            _buildDivider(),
            
            // Условия для пользователей с высокой скидкой
            _buildConditionBlock(
              icon: Icons.diamond_outlined,
              iconColor: Colors.amber.shade700,
              title: 'Особые условия',
              subtitle: 'при скидке от $threshold%',
              items: const [
                _ConditionItem(
                  icon: Icons.info_outline_rounded,
                  text: 'Бонусы не начисляются',
                  isWarning: true,
                ),
                _ConditionItem(
                  icon: Icons.card_giftcard_rounded,
                  text: 'Вместо бонусов вы получите подарок на выбор',
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Примечание
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18.w,
                    color: Colors.orange.shade700,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Бонусы начисляются автоматически после каждой покупки вашего друга. Подарки можно выбрать в разделе "Мои подарки".',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConditionBlock({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required List<_ConditionItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, size: 18.w, color: iconColor),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.black45,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ...items.map((item) => Padding(
          padding: EdgeInsets.only(left: 44.w, bottom: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item.icon,
                size: 16.w,
                color: item.isWarning ? Colors.orange.shade700 : _primaryGreen,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: item.isWarning ? Colors.orange.shade800 : Colors.black54,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
  
  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Divider(
        color: Colors.grey.shade200,
        height: 1,
      ),
    );
  }
  
  String _getPluralPurchases(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'покупки';
    } else if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'покупок';
    } else {
      return 'покупок';
    }
  }
  
  String _getPluralFriends(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'друг';
    } else if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'друга';
    } else {
      return 'друзей';
    }
  }

  // Динамическое описание для шаринга промокода
  Widget _buildShareDescription(DiscountState state) {
    final info = state.referralInfo;
    final text = info != null
        ? info.getShareDescription()
        : 'Поделитесь промокодом с другом и получайте бонусы с его покупок.';
    
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        color: Colors.black54,
        height: 1.4,
      ),
    );
  }
  
  // Динамический текст "Введите и получите скидку X%"
  Widget _buildEnterAndGetDiscountText(DiscountState state) {
    final info = state.referralInfo;
    final discount = info?.newUserDiscountPercent ?? 10;
    
    return Text(
      'Введите и получите скидку $discount%',
      style: TextStyle(
        fontSize: 13.sp,
        color: Colors.black45,
      ),
    );
  }
  
  // Динамическое описание для друга
  Widget _buildFriendDescription(DiscountState state) {
    final info = state.referralInfo;
    final text = info != null
        ? info.getFriendDescription()
        : 'Получите персональную скидку и участвуйте в программе накопления.';
    
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        color: Colors.black54,
        height: 1.4,
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, DiscountState state, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: _accentGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: _accentGreen,
                  size: 36.w,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                l10n.promocodeApplied,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                l10n.promocodeAppliedDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_lightGreen, _primaryGreen]),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Text(
                      l10n.great,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, DiscountState state, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 36.w,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                l10n.promocodeNotFound,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                l10n.promocodeNotFoundDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Text(
                      l10n.enterAgain,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Вспомогательный класс для элемента условия
class _ConditionItem {
  final IconData icon;
  final String text;
  final bool isWarning;

  const _ConditionItem({
    required this.icon,
    required this.text,
    this.isWarning = false,
  });
}
