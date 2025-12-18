import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ketroy_app/core/constants/shop_contacts.dart';
import 'package:ketroy_app/core/util/launch_url.dart';
import 'package:ketroy_app/features/partners/presentation/pages/partners_page.dart';
import 'package:ketroy_app/features/shop/presentation/pages/shop.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:ketroy_app/services/analytics/social_analytics_service.dart';

class BlurLeftNavBar extends StatefulWidget {
  final int pageIndex;
  final Uri? whatsAppUrl;
  final Uri? instaUrl;
  final Uri? twoGisUrl;
  final String? city;
  final Function(int) onTap;

  const BlurLeftNavBar({
    super.key,
    required this.pageIndex,
    required this.onTap,
    this.whatsAppUrl,
    this.instaUrl,
    this.twoGisUrl,
    this.city,
  });

  @override
  State<BlurLeftNavBar> createState() => _BlurLeftNavBarState();
}

class _BlurLeftNavBarState extends State<BlurLeftNavBar>
    with SingleTickerProviderStateMixin {
  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _cardBg = Color(0xFFF5F7F0);

  late AnimationController _animController;

  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _closeDrawer() async {
    if (_isClosing) return;
    _isClosing = true;
    
    await _animController.reverse();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        // Свайп для закрытия
        onHorizontalDragUpdate: (details) {
          // Свайп влево закрывает drawer
          if (details.delta.dx < -5) {
            _closeDrawer();
          }
        },
        child: Stack(
          children: [
            // Затемнённый блюр фон
            GestureDetector(
              onTap: _closeDrawer,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) => BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 15 * _animController.value,
                    sigmaY: 15 * _animController.value,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3 * _animController.value),
                  ),
                ),
              ),
            ),

            // Drawer контент
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animController,
              curve: Curves.easeOutCubic,
            )),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 300.w,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: _cardBg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(5, 0),
                    ),
                  ],
                ),
                child: Column(
                children: [
                  // Header с градиентом
                  _buildHeader(l10n),
                  
                  // Меню
                  Expanded(
                    child: _buildMenuItems(l10n),
                  ),
                  
                  // Социальные сети внизу
                  _buildSocialLinks(l10n),
                  
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24.w, 60.h, 24.w, 24.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryGreen, _lightGreen],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Текст меню
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.menu,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  width: 40.w,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: _accentGreen,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ],
            ),
            
            // Кнопка закрытия
            GestureDetector(
              onTap: _closeDrawer,
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.home_rounded,
            title: l10n.mainMenu,
            isActive: widget.pageIndex == 0,
            onTap: () async {
              widget.onTap(0);
              await _closeDrawer();
            },
            delay: 0,
          ),
          SizedBox(height: 8.h),
          _buildMenuItem(
            icon: Icons.store_rounded,
            title: l10n.shops,
            isActive: widget.pageIndex == 2,
            onTap: () async {
              await _closeDrawer();
              if (!mounted) return;
              Navigator.of(context, rootNavigator: false).push(
                MaterialPageRoute(
                  builder: (context) => const ShopPage(pop: true),
                ),
              );
            },
            delay: 1,
          ),
          SizedBox(height: 8.h),
          _buildMenuItem(
            icon: Icons.handshake_rounded,
            title: l10n.forPartners,
            isActive: widget.pageIndex == 4,
            onTap: () async {
              await _closeDrawer();
              if (!mounted) return;
              Navigator.of(context, rootNavigator: false).push(
                MaterialPageRoute(builder: (context) => const PartnersPage()),
              );
            },
            delay: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (delay * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(-30 * (1 - value), 0),
        child: Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: isActive ? _primaryGreen.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16.r),
            border: isActive
                ? Border.all(color: _primaryGreen.withValues(alpha: 0.2), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: isActive ? _primaryGreen : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: (isActive ? _primaryGreen : Colors.black).withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: isActive ? Colors.white : _primaryGreen,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? _primaryGreen : Colors.black87,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: isActive ? _primaryGreen : Colors.black38,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLinks(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.weInSocials,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black45,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _buildSocialButton(
                asset: 'images/insta.svg',
                onTap: () {
                  final url = widget.instaUrl ?? InstaContacts.almatyInsta;
                  // Трекинг клика Instagram из навбара
                  socialAnalytics.trackInstagramFromNavBar(
                    city: widget.city,
                    url: url.toString(),
                  );
                  launchURL(url);
                },
              ),
              SizedBox(width: 16.w),
              _buildSocialButton(
                asset: 'images/whats.svg',
                onTap: () {
                  final url = widget.whatsAppUrl ?? WhatsAppContacts.almatyWhatsapp;
                  // Трекинг клика WhatsApp из навбара
                  socialAnalytics.trackWhatsAppFromNavBar(
                    city: widget.city,
                    url: url.toString(),
                  );
                  launchURL(url);
                },
              ),
              SizedBox(width: 16.w),
              _buildSocialButton(
                asset: 'images/2gis.svg',
                onTap: () {
                  final url = widget.twoGisUrl ?? Uri.parse('https://go.2gis.com/ketroy');
                  // Трекинг клика 2GIS из навбара
                  socialAnalytics.track2GisFromShop(
                    shopId: 0,
                    shopName: 'KETROY',
                    url: url.toString(),
                  );
                  launchURL(url);
                },
              ),
              SizedBox(width: 16.w),
              _buildSocialButton(
                icon: Icons.local_offer_rounded,
                onTap: () {
                  // Трекинг клика Outlet WhatsApp из навбара
                  socialAnalytics.trackWhatsAppFromNavBar(
                    city: widget.city,
                    url: WhatsAppContacts.outletWhatsapp.toString(),
                  );
                  launchURL(WhatsAppContacts.outletWhatsapp);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    String? asset,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: icon != null
              ? Icon(
                  icon,
                  size: 24.w,
                  color: _primaryGreen,
                )
              : SvgPicture.asset(
                  asset!,
                  width: 24.w,
                  height: 24.w,
                ),
        ),
      ),
    );
  }
}
