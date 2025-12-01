import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/transitions/slide_over_page_route.dart';
import 'package:ketroy_app/core/common/widgets/logout_confirm_dialog.dart';
import 'package:ketroy_app/core/common/widgets/delete_account_confirm_dialog.dart';
import 'package:ketroy_app/features/notification/presentation/pages/notification_settings_page.dart';
import 'package:ketroy_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:ketroy_app/features/settings/presentation/pages/language_settings_page.dart';
import 'package:ketroy_app/services/localization/localization_service.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart' show AppLiquidGlassSettings;
import 'package:provider/provider.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  // Design colors
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _darkBg = Color(0xFF1A1F12);
  static const Color _cardBg = Color(0xFFF5F7F0);

  late AnimationController _animController;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _itemAnimations = List.generate(5, (index) {
      final start = index * 0.1;
      final end = (0.4 + index * 0.15).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(
            start,
            end,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _cardBg,
        body: Stack(
          children: [
            // Gradient header
            Container(
              height: 180.h,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_darkBg, _primaryGreen],
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(l10n),
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
                        child: _buildContent(l10n),
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

  Widget _buildHeader(AppLocalizations l10n) {
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
            child: Column(
              children: [
                Text(
                  l10n.settings,
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
                      Icons.settings_rounded,
                      size: 16.w,
                      color: _accentGreen,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'KETROY',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 1.5,
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

  Widget _buildContent(AppLocalizations l10n) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
      children: [
        // Language settings
        AnimatedBuilder(
          animation: _itemAnimations[0],
          builder: (context, child) {
            final value = _itemAnimations[0].value;
            return Transform.translate(
              offset: Offset(20 * (1 - value), 0),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: _buildSettingsCard(
            icon: Icons.language_rounded,
            title: l10n.language,
            subtitle: _getLanguageSubtitle(l10n),
            onTap: () => _navigateToLanguageSettings(),
          ),
        ),

        SizedBox(height: 16.h),

        // Notification settings
        AnimatedBuilder(
          animation: _itemAnimations[1],
          builder: (context, child) {
            final value = _itemAnimations[1].value;
            return Transform.translate(
              offset: Offset(20 * (1 - value), 0),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: _buildSettingsCard(
            icon: Icons.notifications_rounded,
            title: l10n.notifications,
            subtitle: l10n.managePushNotifications,
            onTap: () => _navigateToNotificationSettings(),
          ),
        ),

        SizedBox(height: 16.h),

        // Logout button
        AnimatedBuilder(
          animation: _itemAnimations[2],
          builder: (context, child) {
            final value = _itemAnimations[2].value;
            return Transform.translate(
              offset: Offset(20 * (1 - value), 0),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: _buildLogoutCard(l10n),
        ),

        SizedBox(height: 32.h),

        // App info
        AnimatedBuilder(
          animation: _itemAnimations[3],
          builder: (context, child) {
            final value = _itemAnimations[3].value;
            return Opacity(opacity: value, child: child);
          },
          child: _buildAppInfo(),
        ),

        SizedBox(height: 40.h),

        // Delete account
        AnimatedBuilder(
          animation: _itemAnimations[4],
          builder: (context, child) {
            final value = _itemAnimations[4].value;
            return Opacity(opacity: value, child: child);
          },
          child: _buildDeleteAccountText(l10n),
        ),

        SizedBox(height: 24.h),
      ],
    );
  }

  String _getLanguageSubtitle(AppLocalizations l10n) {
    final locService = Provider.of<LocalizationService>(context);
    if (locService.isUsingSystemLanguage) {
      return l10n.systemLanguage;
    }
    return locService.currentLanguage.nativeName;
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: _primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                icon,
                color: _primaryGreen,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.black26,
              size: 24.w,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                'images/logoK.png',
                width: 36.w,
                height: 36.w,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.storefront_rounded,
                  color: _primaryGreen,
                  size: 28.w,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'KETROY',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: _primaryGreen,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'v2.0',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(l10n),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                l10n.logoutFromAccount,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.red.withValues(alpha: 0.5),
              size: 24.w,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(AppLocalizations l10n) async {
    final confirmed = await LogoutConfirmDialog.show(context);
    if (confirmed && mounted) {
      context.read<ProfileBloc>().add(LogOutFetch());
    }
  }

  void _navigateToLanguageSettings() {
    Navigator.push(
      context,
      SlideOverPageRoute(page: const LanguageSettingsPage()),
    );
  }

  void _navigateToNotificationSettings() {
    Navigator.push(
      context,
      SlideOverPageRoute(page: const NotificationSettingsPage()),
    );
  }

  Widget _buildDeleteAccountText(AppLocalizations l10n) {
    return Center(
      child: GestureDetector(
        onTap: () => _showDeleteAccountDialog(l10n),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Text(
            l10n.deleteAccount,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.red.withValues(alpha: 0.7),
              decoration: TextDecoration.underline,
              decorationColor: Colors.red.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(AppLocalizations l10n) async {
    final confirmed = await DeleteAccountConfirmDialog.show(context);
    if (confirmed && mounted) {
      context.read<ProfileBloc>().add(DeleteUserFetch());
    }
  }
}

