<?php

use App\Http\Controllers\ActualController;
use App\Http\Controllers\Admin\AdminController;
use App\Http\Controllers\Admin\AnalyticsController;
use App\Http\Controllers\SocialAnalyticsController;
use App\Http\Controllers\CityController;
use App\Http\Controllers\CountryController;
use App\Http\Controllers\ShopReviewController;
use App\Http\Controllers\StoryController;
use App\Http\Controllers\UserController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\AdminAuthController;
use App\Http\Controllers\BannerController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\NewsController;
use App\Http\Controllers\ShopController;
use App\Http\Controllers\BonusCardController;
use App\Http\Controllers\BonusProgramController;
use App\Http\Controllers\GiftCertificateController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\PromoCodeController;
use App\Http\Controllers\TransactionController;
use App\Http\Controllers\PromotionController;
use App\Http\Controllers\GiftController;
use App\Http\Controllers\ClothingAnalyzerController;
use App\Http\Controllers\GiftCatalogController;
use App\Http\Controllers\LoyaltyLevelController;
use App\Http\Controllers\VideoController;
use App\Http\Controllers\UploadController;
use App\Http\Controllers\OneCWebhookController;
use App\Http\Controllers\LotteryController;
use App\Http\Controllers\Admin\PushNotificationController;

/*
|--------------------------------------------------------------------------
| PUBLIC ROUTES (без авторизации)
|--------------------------------------------------------------------------
*/

// Авторизация с rate limiting
Route::middleware('throttle:auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    // FLOW: 
    // 1. Новый пользователь: send-verification-code → verify-code → register
    // 2. Существующий пользователь: login-send-code → verify-code (возвращает token)
    Route::post('/send-verification-code', [AuthController::class, 'sendVerificationCode'])
        ->middleware('throttle:verification');
    Route::post('/login-send-code', [AuthController::class, 'loginSendCode'])
        ->middleware('throttle:verification');
    Route::post('/verify-code', [AuthController::class, 'verifyCode'])
        ->middleware('throttle:verification');
});

// Справочные данные (публичные, только чтение)
Route::get('/country_codes', [CountryController::class, 'index']);
Route::get('/cities', [CityController::class, 'index']);
Route::get('/categories', [CategoryController::class, 'getCategories']);

// Контент (публичный, только чтение)
Route::get('/banners', [BannerController::class, 'index']);
Route::get('/banners/{id}', [BannerController::class, 'show']);
Route::get('/news', [NewsController::class, 'index']);
Route::get('/news/{id}', [NewsController::class, 'show']);
Route::get('/stories', [StoryController::class, 'getActiveStories']);
Route::get('/stories/{id}', [StoryController::class, 'show']);
Route::get('/actuals', [ActualController::class, 'index']);

// Магазины (публичный, только чтение)
Route::get('/shop', [ShopController::class, 'index']);
Route::get('/shop/{id}', [ShopController::class, 'show']);
Route::get('/reviews', [ShopReviewController::class, 'getAllReviews']);
Route::get('/reviews/check/{shopId}/{userId}', [ShopReviewController::class, 'checkUserReview']);

// Акции (публичный, только чтение)
Route::prefix('/promotions')->group(function () {
    Route::get('/', [PromotionController::class, 'index']);
    Route::get('/{id}', [PromotionController::class, 'show']);
});

// Бонусные программы (публичный, только чтение)
Route::get('/bonus-programs', [BonusProgramController::class, 'index']);
Route::get('/bonus-programs/{id}', [BonusProgramController::class, 'show']);

// Уровни лояльности (публичный, только чтение)
Route::get('/loyalty-levels', [LoyaltyLevelController::class, 'index']);

// AI анализатор одежды (требует авторизацию для analyze и chat, health публичный)
Route::prefix('clothing-analyzer')->group(function () {
    Route::post('/analyze', [ClothingAnalyzerController::class, 'analyzeLabel'])->middleware('auth:sanctum');
    Route::post('/chat', [ClothingAnalyzerController::class, 'chat'])->middleware('auth:sanctum');
    Route::get('/health', [ClothingAnalyzerController::class, 'health']);
});

// QR код для скидки (публичный)
Route::get('/static-discount-qrcode', [BonusCardController::class, 'generateDiscountQrCode']);

// Аналитика социальных сетей (публичный endpoint для записи кликов)
Route::post('/analytics/social-click', [SocialAnalyticsController::class, 'trackSocialClick']);

/*
|--------------------------------------------------------------------------
| 1C WEBHOOK ROUTES (защищено X-1C-Secret)
|--------------------------------------------------------------------------
*/
Route::prefix('1c')->middleware('verify.1c.signature')->group(function () {
    Route::post('/purchase', [OneCWebhookController::class, 'handlePurchase']);
    Route::get('/health', [OneCWebhookController::class, 'healthCheck']);
});

/*
|--------------------------------------------------------------------------
| AUTHENTICATED USER ROUTES (требуется авторизация пользователя)
|--------------------------------------------------------------------------
*/

Route::middleware('auth:sanctum')->group(function () {
    // Профиль пользователя
    Route::get('/user', [AuthController::class, 'user']);
    Route::put('/user/update', [UserController::class, 'updateUser']);
    Route::post('/user/avatar', [UserController::class, 'setAvatarImageForUser']);
    Route::post('/user/update-subscription', [UserController::class, 'updateSubscription']);
    Route::delete('/user', [AuthController::class, 'deleteUser']);
    Route::post('/logout', [AuthController::class, 'logout']);
    
    // Управление push-уведомлениями на устройстве
    Route::post('/activate-device', [AuthController::class, 'activateDevice']);
    Route::post('/deactivate-device', [AuthController::class, 'deactivateDevice']);

    // Уровни лояльности пользователя
    Route::get('/user/loyalty', [LoyaltyLevelController::class, 'getUserLoyaltyInfo']);
    Route::get('/user/loyalty/pending-gifts', [LoyaltyLevelController::class, 'getPendingGiftChoices']);
    Route::post('/user/loyalty/select-gift', [LoyaltyLevelController::class, 'selectGift']);

    // Подарки пользователя
    Route::get('/gifts', [UserController::class, 'myGifts']);
    Route::post('/save-gift', [UserController::class, 'saveGift']);
    Route::post('/activate-gift', [UserController::class, 'activateGift']);
    Route::post('/gifts/purchase', [GiftCertificateController::class, 'purchase']);
    
    // Новая система подарков (выбор из нескольких)
    Route::get('/gifts/pending-groups', [GiftController::class, 'getPendingGiftGroups']);
    Route::post('/gifts/activate-by-qr', [GiftController::class, 'activateByQr']);
    Route::post('/gifts/select', [GiftController::class, 'selectGift']);
    Route::post('/gifts/activate', [GiftController::class, 'activateGift']);
    Route::post('/gifts/confirm-issuance', [GiftController::class, 'confirmIssuance']);

    // Бонусная карта
    Route::get('/bonus-card', [BonusCardController::class, 'show']);
    Route::get('/scan-discount', [BonusCardController::class, 'scanDiscount'])->name('scan-discount');
    Route::post('/verify-discount', [BonusCardController::class, 'verifyDiscount']);

    // Промокоды
    Route::post('/promo-codes/apply', [PromoCodeController::class, 'applyPromoCode']);

    // Реферальная система (ВАЖНО: должна быть ПЕРЕД /referral/{code})
    Route::prefix('referral')->group(function () {
        Route::get('/info', [PromoCodeController::class, 'getReferralInfo']); // Информация о программе для мобильного
        Route::post('/generate', [PromoCodeController::class, 'generate']);
        Route::post('/consume', [PromoCodeController::class, 'consume']);
    });
    
    // Редирект по реферальному коду (должен быть ПОСЛЕ конкретных маршрутов)
    Route::get('/referral/{code}', [PromoCodeController::class, 'redirect']);

    // Уведомления
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);
    Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead']); // Отметить ВСЕ как прочитанные (1 запрос)
    Route::post('/notifications/delete-all', [NotificationController::class, 'deleteAllNotifications']);

    // Отзывы (создание)
    Route::post('/reviews', [ShopReviewController::class, 'store']);

    // Лотерея
    Route::prefix('lottery')->group(function () {
        Route::get('/check', [LotteryController::class, 'check']);
        Route::post('/claim', [LotteryController::class, 'claim']);
        Route::post('/dismiss', [LotteryController::class, 'dismiss']);
    });
});

/*
|--------------------------------------------------------------------------
| ADMIN ROUTES (требуется авторизация админа)
|--------------------------------------------------------------------------
*/

// Авторизация админов
Route::prefix('admin')->group(function () {
    Route::post('/login', [AdminAuthController::class, 'login'])->middleware('throttle:auth');
    Route::post('/logout', [AdminAuthController::class, 'logout'])->middleware('auth:sanctum');
});

// Админские роуты (требуют авторизации)
Route::middleware(['auth:sanctum'])->prefix('admin')->group(function () {

    // Контент-менеджмент (для маркетологов и супер-админов)
    Route::get('/banners', [BannerController::class, 'getAllBanners']);
    Route::get('/news', [NewsController::class, 'getAllNews']);
    Route::get('/stories', [StoryController::class, 'getAllStories']);

    // CRUD баннеров
    Route::post('/banners', [BannerController::class, 'store']);
    Route::put('/banners/{id}', [BannerController::class, 'update']);
    Route::patch('/banners/{id}', [BannerController::class, 'quickUpdate']);
    Route::post('/banners/reorder', [BannerController::class, 'reorder']);
    Route::delete('/banners/{id}', [BannerController::class, 'destroy']);

    // CRUD новостей
    Route::post('/news', [NewsController::class, 'store']);
    Route::put('/news/{id}', [NewsController::class, 'update']);
    Route::patch('/news/{id}', [NewsController::class, 'quickUpdate']);
    Route::post('/news/reorder', [NewsController::class, 'reorder']);
    Route::delete('/news/{id}', [NewsController::class, 'destroy']);
    
    // Архив новостей
    Route::get('/news/archived', [NewsController::class, 'getArchivedNews']);
    Route::post('/news/{id}/archive', [NewsController::class, 'archive']);
    Route::post('/news/{id}/restore', [NewsController::class, 'restore']);
    Route::post('/news/archive-many', [NewsController::class, 'archiveMany']);

    // CRUD stories
    Route::post('/stories', [StoryController::class, 'store']);
    Route::put('/stories/{id}', [StoryController::class, 'update']);
    Route::post('/stories/bulk-delete', [StoryController::class, 'bulkDestroy']);
    Route::post('/stories/reorder', [StoryController::class, 'reorder']);
    Route::delete('/stories/{id}', [StoryController::class, 'destroy']);

    // CRUD магазинов
    Route::post('/shop', [ShopController::class, 'store']);
    Route::put('/shop/{id}', [ShopController::class, 'update']);
    Route::delete('/shop/{id}', [ShopController::class, 'destroy']);

    // CRUD категорий
    Route::get('/categories', [CategoryController::class, 'getAllCategories']);
    Route::post('/categories', [CategoryController::class, 'store']);

    // CRUD городов
    Route::post('/cities', [CityController::class, 'store']);

    // CRUD actuals
    Route::post('/actuals', [ActualController::class, 'store']);
    Route::post('/actuals/reorder', [ActualController::class, 'reorder']);
    Route::get('/actuals/{id}', [ActualController::class, 'show']);
    Route::delete('/actuals/{id}', [ActualController::class, 'destroy']);

    // CRUD страновых кодов
    Route::post('/country_codes', [CountryController::class, 'store']);

    // Управление акциями
    Route::prefix('promotions')->group(function () {
        Route::get('/', [PromotionController::class, 'index']);
        Route::get('/archived', [PromotionController::class, 'archived']);
        Route::get('/{id}', [PromotionController::class, 'show']);
        Route::post('/', [PromotionController::class, 'store']);
        Route::post('/{id}', [PromotionController::class, 'update']);
        Route::patch('/{id}/toggle-active', [PromotionController::class, 'toggleActive']);
        Route::post('/{id}/archive', [PromotionController::class, 'archive']);
        Route::delete('/{id}', [PromotionController::class, 'destroy']);
    });

    // Каталог подарков
    Route::prefix('gift-catalog')->group(function () {
        Route::get('/', [GiftCatalogController::class, 'index']); // Активные подарки
        Route::get('/all', [GiftCatalogController::class, 'all']); // Все подарки с пагинацией
        Route::get('/{id}', [GiftCatalogController::class, 'show']);
        Route::post('/', [GiftCatalogController::class, 'store']);
        Route::put('/{id}', [GiftCatalogController::class, 'update']);
        Route::delete('/{id}', [GiftCatalogController::class, 'destroy']);
    });

    // Система геймификации / Уровни лояльности
    Route::prefix('loyalty-levels')->group(function () {
        Route::get('/', [LoyaltyLevelController::class, 'index']);
        Route::get('/gifts', [LoyaltyLevelController::class, 'getAvailableGifts']);
        Route::get('/{id}', [LoyaltyLevelController::class, 'show']);
        Route::post('/', [LoyaltyLevelController::class, 'store']);
        Route::put('/{id}', [LoyaltyLevelController::class, 'update']);
        Route::delete('/{id}', [LoyaltyLevelController::class, 'destroy']);
        Route::post('/reorder', [LoyaltyLevelController::class, 'reorder']);
    });

    // Управление бонусными программами
    Route::post('/bonus-programs', [BonusProgramController::class, 'store']);
    Route::put('/bonus-programs/{id}', [BonusProgramController::class, 'update']);
    Route::delete('/bonus-programs/{id}', [BonusProgramController::class, 'destroy']);

    // Управление отзывами
    Route::delete('/reviews/{id}', [ShopReviewController::class, 'deleteReview']);
    
    // Конвертация видео в GIF
    Route::prefix('video-to-gif')->group(function () {
        Route::post('/', [VideoController::class, 'convertToGif']);
        Route::post('/base64', [VideoController::class, 'convertBase64ToGif']);
        Route::get('/info', [VideoController::class, 'info']);
    });
    
    // Универсальная загрузка файлов (видео автоматически конвертируется в GIF)
    Route::post('/upload', [UploadController::class, 'upload']);

    // Пользователи и подарки
    Route::get('/users-with-gifts', [UserController::class, 'getUsersWithGiftCount']);
    Route::get('/users/{id}/gifts', [UserController::class, 'show']);

    // Аналитика
    Route::get('/event-statistics', [AnalyticsController::class, 'getEventStatistics']);
    Route::get('/event-statistics-detailed', [AnalyticsController::class, 'getDetailedEventStatistics']);
    Route::get('/promo-code-usage', [AnalyticsController::class, 'getPromoCodeUsage']);
    Route::get('/social-click-statistics', [SocialAnalyticsController::class, 'getSocialClickStatistics']);
    Route::get('/referral-statistics', [AnalyticsController::class, 'getReferralStatistics']);

    // Push-уведомления (кастомные)
    Route::prefix('push-notifications')->group(function () {
        Route::get('/', [PushNotificationController::class, 'index']);
        Route::get('/stats', [PushNotificationController::class, 'stats']);
        Route::get('/targeting-options', [PushNotificationController::class, 'getTargetingOptions']);
        Route::post('/preview-recipients', [PushNotificationController::class, 'previewRecipients']);
        Route::get('/{id}', [PushNotificationController::class, 'show']);
        Route::post('/', [PushNotificationController::class, 'store']);
        Route::put('/{id}', [PushNotificationController::class, 'update']);
        Route::delete('/{id}', [PushNotificationController::class, 'destroy']);
        Route::post('/{id}/send', [PushNotificationController::class, 'sendNow']);
        Route::post('/{id}/cancel', [PushNotificationController::class, 'cancel']);
        Route::post('/{id}/duplicate', [PushNotificationController::class, 'duplicate']);
    });
});

// Публичные эндпоинты для пользователей (без авторизации админа)
Route::get('/users', [UserController::class, 'getUsers'])->name('users.index');
Route::get('/users-amount', [UserController::class, 'getUsersCount']);
Route::get('/users/{id}', [UserController::class, 'getUserInfo']);
Route::get('/users/{id}/purchases', [UserController::class, 'getPurchaseHistory']);

// Управление пользователями (администрирование)
Route::post('/users/{id}/discount', [UserController::class, 'updatePersonalDiscount']);
Route::post('/users/{id}/bonuses/add', [UserController::class, 'addBonuses']);
Route::post('/users/{id}/bonuses/deduct', [UserController::class, 'deductBonuses']);
Route::post('/users/{id}/gift', [UserController::class, 'sendGift']);
Route::post('/users/{id}/test-notification', [UserController::class, 'sendTestNotification']);

// Управление подарками (админка - вкладка "Выдача")
Route::get('/admin/gifts', [GiftController::class, 'index']);
Route::get('/admin/gifts/stats', [GiftController::class, 'getStats']);
Route::post('/admin/gifts/{id}/issue', [GiftController::class, 'issueGift']);
Route::put('/admin/gifts/{id}/status', [GiftController::class, 'updateStatus']);
Route::post('/admin/gifts/{id}/notify', [GiftController::class, 'sendNotification']);

/*
|--------------------------------------------------------------------------
| SUPER-ADMIN ONLY ROUTES
|--------------------------------------------------------------------------
*/

Route::middleware(['auth:sanctum', 'role:super-admin'])->group(function () {
    // Управление админами
    Route::post('/admins/register', [AdminAuthController::class, 'register']);
    Route::post('/admins/change-role', [AdminController::class, 'changeRole']);
    Route::get('/admins', [UserController::class, 'getUsersWithRoles'])->name('admins.index');
    Route::get('/admins/{id}', [AdminController::class, 'getAdminInfo']);
});

/*
|--------------------------------------------------------------------------
| INTEGRATION ROUTES (для внешних систем)
|--------------------------------------------------------------------------
*/

// 1C интеграция
Route::middleware('1c.token')->post('/process-transaction', [TransactionController::class, 'processTransactions']);
