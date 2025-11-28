import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/services/localization/localization_service.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage>
    with SingleTickerProviderStateMixin {
  // Design colors
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _darkBg = Color(0xFF1A1F12);
  static const Color _cardBg = Color(0xFFF5F7F0);

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locService = Provider.of<LocalizationService>(context);

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
                        child: _buildContent(l10n, locService),
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
                  l10n.language,
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
                      Icons.translate_rounded,
                      size: 16.w,
                      color: _accentGreen,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      l10n.selectLanguage,
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

  Widget _buildContent(AppLocalizations l10n, LocalizationService locService) {
    final languages = LocalizationService.availableLanguages;

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
      children: [
        // System language option (first, separate)
        _buildLanguageOption(
          language: AppLanguage.system,
          isSelected: locService.currentLanguage == AppLanguage.system,
          locService: locService,
          l10n: l10n,
          index: 0,
        ),

        SizedBox(height: 24.h),

        // Section title
        Text(
          l10n.selectLanguage,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),

        SizedBox(height: 16.h),

        // Language list (excluding system)
        ...languages
            .where((lang) => lang != AppLanguage.system)
            .toList()
            .asMap()
            .entries
            .map((entry) {
          final index = entry.key + 1;
          final language = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildLanguageOption(
              language: language,
              isSelected: locService.currentLanguage == language,
              locService: locService,
              l10n: l10n,
              index: index,
            ),
          );
        }),

        SizedBox(height: 24.h),

        // Info block
        _buildInfoBlock(l10n),
      ],
    );
  }

  Widget _buildLanguageOption({
    required AppLanguage language,
    required bool isSelected,
    required LocalizationService locService,
    required AppLocalizations l10n,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) => Transform.translate(
        offset: Offset(20 * (1 - animValue), 0),
        child: Opacity(
          opacity: animValue.clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => _selectLanguage(language, locService),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isSelected ? _primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: isSelected
                ? null
                : Border.all(
                    color: Colors.black.withValues(alpha: 0.05),
                    width: 1,
                  ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? _primaryGreen.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: isSelected ? 15 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Flag or system icon
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : _cardBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: language == AppLanguage.system
                      ? Icon(
                          Icons.phone_android_rounded,
                          size: 24.w,
                          color: isSelected ? Colors.white : _primaryGreen,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: Image.asset(
                            language.flagAsset,
                            width: 28.w,
                            height: 20.w,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.language_rounded,
                              size: 24.w,
                              color: isSelected ? Colors.white : _primaryGreen,
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language == AppLanguage.system
                          ? l10n.systemLanguage
                          : language.nativeName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (language == AppLanguage.system) ...[
                      SizedBox(height: 2.h),
                      Text(
                        _getSystemLanguageHint(locService),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.black45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: const BoxDecoration(
                    color: _accentGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18.w,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSystemLanguageHint(LocalizationService locService) {
    final effectiveLocale = locService.effectiveLocale;
    switch (effectiveLocale.languageCode) {
      case 'ru':
        return 'Русский';
      case 'kk':
        return 'Қазақша';
      case 'en':
        return 'English';
      case 'tr':
        return 'Türkçe';
      default:
        return effectiveLocale.languageCode;
    }
  }

  Widget _buildInfoBlock(AppLocalizations l10n) {
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
              Icons.info_outline_rounded,
              color: _primaryGreen,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                l10n.systemLanguageHint,
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

  void _selectLanguage(AppLanguage language, LocalizationService locService) {
    locService.setLanguage(language);
  }
}

