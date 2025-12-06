import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart' show LiquidGlassButton;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage>
    with SingleTickerProviderStateMixin {
  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _cardBg = Color(0xFFF5F7F0);

  late AnimationController _animController;

  // Настройки уведомлений
  bool _allNotifications = true;
  bool _newsNotifications = true;
  bool _giftsNotifications = true;
  bool _discountsNotifications = true;
  bool _bonusNotifications = true;
  bool _systemNotifications = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadSettings();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _allNotifications = prefs.getBool('notif_all') ?? true;
      _newsNotifications = prefs.getBool('notif_news') ?? true;
      _giftsNotifications = prefs.getBool('notif_gifts') ?? true;
      _discountsNotifications = prefs.getBool('notif_discounts') ?? true;
      _bonusNotifications = prefs.getBool('notif_bonus') ?? true;
      _systemNotifications = prefs.getBool('notif_system') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_all', _allNotifications);
    await prefs.setBool('notif_news', _newsNotifications);
    await prefs.setBool('notif_gifts', _giftsNotifications);
    await prefs.setBool('notif_discounts', _discountsNotifications);
    await prefs.setBool('notif_bonus', _bonusNotifications);
    await prefs.setBool('notif_system', _systemNotifications);
  }

  void _toggleAll(bool value) {
    setState(() {
      _allNotifications = value;
      if (value) {
        _newsNotifications = true;
        _giftsNotifications = true;
        _discountsNotifications = true;
        _bonusNotifications = true;
        _systemNotifications = true;
      }
    });
    _saveSettings();
  }

  void _toggleCategory(String category, bool value) {
    setState(() {
      switch (category) {
        case 'news':
          _newsNotifications = value;
          break;
        case 'gifts':
          _giftsNotifications = value;
          break;
        case 'discounts':
          _discountsNotifications = value;
          break;
        case 'bonus':
          _bonusNotifications = value;
          break;
        case 'system':
          _systemNotifications = value;
          break;
      }
      // Проверяем, все ли включены
      _allNotifications = _newsNotifications &&
          _giftsNotifications &&
          _discountsNotifications &&
          _bonusNotifications &&
          _systemNotifications;
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _cardBg,
        body: Stack(
          children: [
            // Градиентный header
            Container(
              height: 180.h,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1F12), _primaryGreen],
                ),
              ),
            ),

            // Контент
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(top: 16.h),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32.r),
                          topRight: Radius.circular(32.r),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32.r),
                          topRight: Radius.circular(32.r),
                        ),
                        child: _buildContent(),
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

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          LiquidGlassButton(
            onTap: () => Navigator.pop(context),
            width: 44.w,
            height: 44.w,
            borderRadius: 22.0,
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
                  l10n.notificationSettings,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_rounded,
                      size: 16.w,
                      color: _accentGreen,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      l10n.managePushNotifications,
                      style: TextStyle(
                        fontSize: 12.sp,
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

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
      children: [
        // Главный переключатель
        _buildMainSwitch(),
        
        SizedBox(height: 24.h),
        
        // Заголовок категорий
        Text(
          l10n.notificationCategories,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        
        SizedBox(height: 16.h),
        
        // Категории
        _buildCategoryItem(
          icon: Icons.newspaper_rounded,
          title: l10n.newsAndPromotions,
          subtitle: l10n.newsDescription,
          value: _newsNotifications,
          onChanged: (v) => _toggleCategory('news', v),
          delay: 0,
        ),
        _buildCategoryItem(
          icon: Icons.card_giftcard_rounded,
          title: l10n.gifts,
          subtitle: l10n.giftsDescription,
          value: _giftsNotifications,
          onChanged: (v) => _toggleCategory('gifts', v),
          delay: 1,
        ),
        _buildCategoryItem(
          icon: Icons.discount_rounded,
          title: l10n.discounts,
          subtitle: l10n.discountsDescription,
          value: _discountsNotifications,
          onChanged: (v) => _toggleCategory('discounts', v),
          delay: 2,
        ),
        _buildCategoryItem(
          icon: Icons.stars_rounded,
          title: l10n.bonusNotifications,
          subtitle: l10n.bonusDescription,
          value: _bonusNotifications,
          onChanged: (v) => _toggleCategory('bonus', v),
          delay: 3,
        ),
        _buildCategoryItem(
          icon: Icons.info_rounded,
          title: l10n.systemNotifications,
          subtitle: l10n.systemDescription,
          value: _systemNotifications,
          onChanged: (v) => _toggleCategory('system', v),
          delay: 4,
        ),
        
        SizedBox(height: 32.h),
        
        // Информационный блок
        _buildInfoBlock(),
      ],
    );
  }

  Widget _buildMainSwitch() {
    final l10n = AppLocalizations.of(context)!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryGreen,
              _lightGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                _allNotifications
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                color: Colors.white,
                size: 28.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.allNotifications,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _allNotifications ? l10n.enabled : l10n.disabled,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _allNotifications,
              onChanged: _toggleAll,
              activeThumbColor: Colors.white,
              activeTrackColor: _accentGreen,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required int delay,
  }) {
    final isEnabled = _allNotifications;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (delay * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - animValue)),
        child: Opacity(
          opacity: animValue.clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: isEnabled && value
                    ? _primaryGreen.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: isEnabled && value ? _primaryGreen : Colors.grey,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isEnabled ? Colors.black45 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value && isEnabled,
              onChanged: isEnabled ? onChanged : null,
              activeThumbColor: _primaryGreen,
              activeTrackColor: _accentGreen.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBlock() {
    final l10n = AppLocalizations.of(context)!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: child,
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: _accentGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _accentGreen.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: _primaryGreen,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                l10n.notificationSettingsHint,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: _primaryGreen,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

