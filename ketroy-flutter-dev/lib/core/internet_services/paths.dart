/// ============================================
/// KETROY APP - API PATHS
/// ============================================
/// Все API endpoints приложения
library paths;

import 'package:ketroy_app/core/config/app_config.dart';

// ============================================
// BASE URL (из конфигурации)
// ============================================
String get baseUrl => AppConfig.baseUrl;

// ============================================
// AUTH ENDPOINTS
// ============================================
const String register = '/register';
const String sendVerifyCodePath = '/send-verification-code';
const String loginSendCodePath = '/login-send-code';
const String verifyCode = '/verify-code';
const String logOutUrl = '/logout';

// ============================================
// USER ENDPOINTS
// ============================================
const String userUrl = '/user';
const String update = '/user/update';
const String uploadAvatarUrl = '/user/avatar';
const String deviceTokenPostUrl = '/user/update-subscription';
const String usersAmountUrl = '/users-amount';

// ============================================
// REFERENCE DATA ENDPOINTS
// ============================================
const String countryCodesPath = '/country_codes';
const String cityPath = '/cities';
const String categories = '/categories';

// ============================================
// CONTENT ENDPOINTS
// ============================================
const String banners = '/banners';
const String news = '/news';
const String actuals = '/stories';

// ============================================
// SHOP ENDPOINTS
// ============================================
const String shop = '/shop';
const String reviews = '/reviews';

// ============================================
// GIFTS & BONUSES ENDPOINTS
// ============================================
const String giftsUrl = '/gifts';
const String activateGiftUrl = '/activate-gift';
const String saveGiftUrl = '/save-gift';
const String bonusPrograms = '/bonus-programs';

// Новая система подарков (выбор из нескольких)
const String pendingGiftGroupsUrl = '/gifts/pending-groups';
const String activateGiftByQrUrl = '/gifts/activate-by-qr';
const String selectGiftUrl = '/gifts/select';
const String newActivateGiftUrl = '/gifts/activate';
const String confirmGiftIssuanceUrl = '/gifts/confirm-issuance'; // Подтверждение выдачи по QR

// ============================================
// PROMO & DISCOUNT ENDPOINTS
// ============================================
const String promoCodeApply = '/promo-codes/apply';
const String verifyDiscountUrl = '/verify-discount';
const String referralInfoUrl = '/referral/info';

// ============================================
// NOTIFICATIONS ENDPOINTS
// ============================================
const String notificationUrl = '/notifications';

// ============================================
// AI ENDPOINTS
// ============================================
const String clothingAnalyze = '/clothing-analyzer/analyze';
const String clothingChat = '/clothing-analyzer/chat';

// ============================================
// ANALYTICS ENDPOINTS
// ============================================
const String socialClickAnalytics = '/analytics/social-click';

// ============================================
// LOTTERY ENDPOINTS
// ============================================
const String lotteryCheckUrl = '/lottery/check';
const String lotteryClaimUrl = '/lottery/claim';
const String lotteryDismissUrl = '/lottery/dismiss';

// ============================================
// PROMOTIONS ENDPOINTS
// ============================================
const String promotionsUrl = '/promotions';
