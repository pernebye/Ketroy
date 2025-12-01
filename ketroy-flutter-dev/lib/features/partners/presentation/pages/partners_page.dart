import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart' show LiquidGlassButton;
import 'package:ketroy_app/core/transitions/slide_over_page_route.dart';
import 'package:ketroy_app/features/partners/presentation/bloc/partners_bloc.dart';
import 'package:ketroy_app/services/analytics/social_analytics_service.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class PartnersPage extends StatefulWidget {
  const PartnersPage({super.key});

  @override
  State<PartnersPage> createState() => _PartnersPageState();
}

class _PartnersPageState extends State<PartnersPage>
    with SingleTickerProviderStateMixin {
  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _darkBg = Color(0xFF1A1F12);
  static const Color _cardBg = Color(0xFFF5F7F0);
  static const Color _whatsAppGreen = Color(0xFF25D366);

  final url = Uri.parse('https://wa.me/77027061350');

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    context.read<PartnersBloc>().add(GetAmountDataFetch());

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

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
      child: SwipeBackWrapper(
        child: Scaffold(
          backgroundColor: _cardBg,
          body: BlocBuilder<PartnersBloc, PartnersState>(
            builder: (context, state) {
              return Stack(
                children: [
                  // Фоновый градиент
                  _buildBackground(),

                  // Основной контент
                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Header
                      SliverToBoxAdapter(
                        child: _buildHeader(l10n),
                      ),

                      // Контент
                      SliverToBoxAdapter(
                        child: _buildContent(l10n, state),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      height: 380.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _darkBg,
            _primaryGreen,
            _lightGreen.withValues(alpha: 0.9),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Toolbar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Row(
              children: [
                _buildBackButton(),
                const Spacer(),
                Text(
                  l10n.forPartners,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                SizedBox(width: 44.w),
              ],
            ),
          ),

          // Иллюстрация и заголовок
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  // Иконка партнерства
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _accentGreen.withValues(alpha: 0.3),
                          _lightGreen.withValues(alpha: 0.2),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.handshake_rounded,
                      size: 48.w,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    l10n.forPartners.toUpperCase(),
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: 60.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: _accentGreen,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return LiquidGlassButton(
      onTap: () => Navigator.of(context).pop(),
      width: 44.w,
      height: 44.w,
      child: Icon(
        Icons.arrow_back_ios_new_rounded,
        color: Colors.white,
        size: 20.sp,
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n, PartnersState state) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            // Статистика пользователей
            _buildStatsCard(l10n, state),
            SizedBox(height: 20.h),

            // Карточка с информацией
            _buildInfoCard(l10n),
            SizedBox(height: 20.h),

            // Кнопка WhatsApp
            _buildWhatsAppButton(l10n),
            SizedBox(height: 24.h),

            // Преимущества партнерства
            _buildBenefitsSection(l10n),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(AppLocalizations l10n, PartnersState state) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primaryGreen, _lightGreen],
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_alt_rounded,
                  color: _accentGreen,
                  size: 28.w,
                ),
                SizedBox(width: 12.w),
                Text(
                  l10n.usAlready,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _AnimatedCounter(
              value: state.amount ?? '0',
              style: TextStyle(
                fontSize: 48.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.users.toUpperCase(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: _accentGreen,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations l10n) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                    color: _primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.mail_outline_rounded,
                    color: _primaryGreen,
                    size: 24.w,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    l10n.contactUs,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: _primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.partnershipDescription,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppButton(AppLocalizations l10n) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          socialAnalytics.trackWhatsAppFromPartners(url: url.toString());
          launchUrl(url);
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 18.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_whatsAppGreen, Color(0xFF128C7E)],
            ),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: _whatsAppGreen.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'images/logo-whats.svg',
                width: 28.w,
                height: 28.w,
              ),
              SizedBox(width: 12.w),
              Text(
                l10n.writeToWhatsApp,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitsSection(AppLocalizations l10n) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.partnershipBenefits,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: _primaryGreen,
              ),
            ),
            SizedBox(height: 20.h),
            _buildBenefitItem(
              icon: Icons.ads_click_rounded,
              title: l10n.benefitAds,
              delay: 0,
            ),
            _buildBenefitItem(
              icon: Icons.campaign_rounded,
              title: l10n.benefitPromo,
              delay: 1,
            ),
            _buildBenefitItem(
              icon: Icons.business_rounded,
              title: l10n.benefitBusiness,
              delay: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (delay * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(-20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: _accentGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: _primaryGreen,
                size: 22.w,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Анимированный счётчик для отображения количества пользователей
class _AnimatedCounter extends StatelessWidget {
  final String value;
  final TextStyle style;

  const _AnimatedCounter({
    required this.value,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(
        begin: 0,
        end: int.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ?? 0,
      ),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        // Форматируем число с пробелами
        final formatted = _formatNumber(animValue);
        return Text(formatted, style: style);
      },
    );
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
