<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Services\AnalyticsService;
use App\Models\User;
use App\Models\UserReferralReward;
use App\Models\Promotion;
use App\Models\Purchase;
use App\Models\Gift;
use Illuminate\Support\Facades\DB;

class AnalyticsController extends Controller
{
    protected $analyticsService;

    public function __construct(AnalyticsService $analyticsService)
    {
        $this->analyticsService = $analyticsService;
    }

    /**
     * @OA\Get(
     *     path="/event-statistics",
     *     summary="Получение статистики по событиям",
     *     description="Получение статистики по событиям в заданном периоде.",
     *     tags={"Analytics"},
     *     @OA\Parameter(
     *         name="type",
     *         in="query",
     *         description="Тип события для статистики (например, 'login', 'purchase')",
     *         required=false,
     *         @OA\Schema(
     *             type="string",
     *             example="login"
     *         )
     *     ),
     *     @OA\Parameter(
     *         name="start_date",
     *         in="query",
     *         description="Дата начала периода (по умолчанию - 1 месяц назад)",
     *         required=false,
     *         @OA\Schema(
     *             type="string",
     *             format="date",
     *             example="2024-11-01"
     *         )
     *     ),
     *     @OA\Parameter(
     *         name="end_date",
     *         in="query",
     *         description="Дата конца периода (по умолчанию - сегодня)",
     *         required=false,
     *         @OA\Schema(
     *             type="string",
     *             format="date",
     *             example="2024-12-01"
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Статистика по событиям успешно получена",
     *         @OA\JsonContent(
     *             @OA\Property(property="data", type="object", additionalProperties=true),
     *             @OA\Property(property="message", type="string", example="Event statistics fetched successfully")
     *         )
     *     )
     * )
     */
    public function getEventStatistics(Request $request)
    {
        $type = $request->get('type');
        $startDate = $request->get('start_date', now()->subMonth());
        $endDate = $request->get('end_date', now());

        return response()->json(
            $this->analyticsService->getEventStatistics($type, $startDate, $endDate)
        );
    }

    /**
     * @OA\Get(
     *     path="/event-statistics-detailed",
     *     summary="Получение детальной статистики по конкретным объектам",
     *     description="Получение статистики просмотров по конкретным постам, сторис или баннерам.",
     *     tags={"Analytics"},
     *     @OA\Parameter(
     *         name="type",
     *         in="query",
     *         description="Тип контента (post, story, banner)",
     *         required=true,
     *         @OA\Schema(type="string", example="post")
     *     ),
     *     @OA\Parameter(
     *         name="start_date",
     *         in="query",
     *         description="Дата начала периода",
     *         required=false,
     *         @OA\Schema(type="string", format="date", example="2024-11-01")
     *     ),
     *     @OA\Parameter(
     *         name="end_date",
     *         in="query",
     *         description="Дата конца периода",
     *         required=false,
     *         @OA\Schema(type="string", format="date", example="2024-12-01")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Детальная статистика успешно получена"
     *     )
     * )
     */
    public function getDetailedEventStatistics(Request $request)
    {
        $type = $request->get('type', 'post');
        $startDate = $request->get('start_date', now()->subMonth());
        $endDate = $request->get('end_date', now());

        return response()->json(
            $this->analyticsService->getDetailedEventStatistics($type, $startDate, $endDate)
        );
    }

    /**
     * @OA\Get(
     *     path="/promo-code-usage",
     *     summary="Получение статистики использования промокодов",
     *     description="Получение статистики по использованию промокодов за заданный период.",
     *     tags={"Analytics"},
     *     @OA\Parameter(
     *         name="start_date",
     *         in="query",
     *         description="Дата начала периода (по умолчанию - 1 месяц назад)",
     *         required=false,
     *         @OA\Schema(
     *             type="string",
     *             format="date",
     *             example="2024-11-01"
     *         )
     *     ),
     *     @OA\Parameter(
     *         name="end_date",
     *         in="query",
     *         description="Дата конца периода (по умолчанию - сегодня)",
     *         required=false,
     *         @OA\Schema(
     *             type="string",
     *             format="date",
     *             example="2024-12-01"
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Статистика использования промокодов успешно получена",
     *         @OA\JsonContent(
     *             @OA\Property(property="data", type="object", additionalProperties=true),
     *             @OA\Property(property="message", type="string", example="Promo code usage fetched successfully")
     *         )
     *     )
     * )
     */
    public function getPromoCodeUsage(Request $request)
    {
        $startDate = $request->get('start_date', now()->subMonth());
        $endDate = $request->get('end_date', now());

        return response()->json(
            $this->analyticsService->getPromoCodeUsage($startDate, $endDate)
        );
    }

    /**
     * @OA\Get(
     *     path="/admin/referral-statistics",
     *     summary="Получение статистики реферальной программы 'Подари скидку другу'",
     *     description="Детальная статистика по акции 'Подари скидку другу'",
     *     tags={"Analytics"},
     *     security={{"bearerAuth":{}}},
     *     @OA\Parameter(
     *         name="start_date",
     *         in="query",
     *         description="Дата начала периода",
     *         required=false,
     *         @OA\Schema(type="string", format="date", example="2024-11-01")
     *     ),
     *     @OA\Parameter(
     *         name="end_date",
     *         in="query",
     *         description="Дата конца периода",
     *         required=false,
     *         @OA\Schema(type="string", format="date", example="2024-12-01")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Статистика успешно получена"
     *     )
     * )
     */
    public function getReferralStatistics(Request $request)
    {
        $startDate = $request->get('start_date', now()->subMonth()->toDateString());
        $endDate = $request->get('end_date', now()->toDateString());

        $startDateTime = $startDate . ' 00:00:00';
        $endDateTime = $endDate . ' 23:59:59';

        // Получаем активную акцию "Подари скидку другу"
        $promotion = Promotion::where('type', 'friend_discount')
            ->where('is_archived', false)
            ->first();

        // === ОСНОВНЫЕ МЕТРИКИ ===
        
        // Общее количество применённых промокодов за период
        $totalApplied = UserReferralReward::whereBetween('applied_at', [$startDateTime, $endDateTime])->count();
        
        // Всего применено за всё время
        $totalAppliedAllTime = UserReferralReward::count();

        // Количество уникальных рефереров (тех, чьи промокоды применили)
        $uniqueReferrers = UserReferralReward::whereBetween('applied_at', [$startDateTime, $endDateTime])
            ->distinct('referrer_id')
            ->count('referrer_id');

        // Количество новых пользователей по реферальной программе за период
        $newReferredUsers = User::whereNotNull('referrer_id')
            ->whereBetween('created_at', [$startDateTime, $endDateTime])
            ->count();

        // === ДИНАМИКА ПО ДНЯМ ===
        $byDate = UserReferralReward::whereBetween('applied_at', [$startDateTime, $endDateTime])
            ->selectRaw("DATE(applied_at) as date, COUNT(*) as applications")
            ->groupBy('date')
            ->orderBy('date', 'asc')
            ->get();

        // === ТОП РЕФЕРЕРОВ ===
        $topReferrers = UserReferralReward::whereBetween('applied_at', [$startDateTime, $endDateTime])
            ->selectRaw('referrer_id, COUNT(*) as referred_count')
            ->groupBy('referrer_id')
            ->orderBy('referred_count', 'desc')
            ->limit(20)
            ->with(['referrer:id,name,surname,phone'])
            ->get()
            ->map(function ($item) {
                return [
                    'referrer_id' => $item->referrer_id,
                    'referrer_name' => $item->referrer ? 
                        trim(($item->referrer->name ?? '') . ' ' . ($item->referrer->surname ?? '')) : 'Неизвестно',
                    'referrer_phone' => $item->referrer->phone ?? null,
                    'referred_count' => $item->referred_count,
                ];
            });

        // === КОНВЕРСИЯ ===
        // Пользователи, применившие промокод и совершившие хотя бы 1 покупку
        $referredWithPurchases = User::whereNotNull('referrer_id')
            ->whereHas('purchases')
            ->whereBetween('created_at', [$startDateTime, $endDateTime])
            ->count();

        $conversionRate = $newReferredUsers > 0 
            ? round(($referredWithPurchases / $newReferredUsers) * 100, 1) 
            : 0;

        // === СТАТИСТИКА ПО ПОКУПКАМ РЕФЕРАЛОВ ===
        $referredUserIds = User::whereNotNull('referrer_id')
            ->whereBetween('created_at', [$startDateTime, $endDateTime])
            ->pluck('id');

        $purchaseStats = Purchase::whereIn('user_id', $referredUserIds)
            ->selectRaw('COUNT(*) as total_purchases, COALESCE(SUM(total_price), 0) as total_amount')
            ->first();

        // === ПОДАРКИ ВЫДАННЫЕ РЕФЕРЕРРАМ ===
        $giftsToReferrers = 0;
        if ($promotion) {
            $giftsToReferrers = Gift::where('promotion_id', $promotion->id)
                ->whereBetween('created_at', [$startDateTime, $endDateTime])
                ->count();
        }

        // === НАСТРОЙКИ АКЦИИ ===
        $promotionSettings = null;
        if ($promotion) {
            $settings = is_array($promotion->settings) 
                ? $promotion->settings 
                : json_decode($promotion->settings, true);
            
            $promotionSettings = [
                'id' => $promotion->id,
                'name' => $promotion->name,
                'is_active' => $promotion->is_active,
                'referrer_bonus_percent' => $settings['referrer_bonus_percent'] ?? 2,
                'referrer_max_purchases' => $settings['referrer_max_purchases'] ?? 3,
                'new_user_discount_percent' => $settings['new_user_discount_percent'] ?? 10,
                'new_user_bonus_percent' => $settings['new_user_bonus_percent'] ?? 5,
            ];
        }

        // === ПОСЛЕДНИЕ ПРИМЕНЕНИЯ ===
        $recentApplications = UserReferralReward::whereBetween('applied_at', [$startDateTime, $endDateTime])
            ->with(['user:id,name,surname,phone', 'referrer:id,name,surname,phone'])
            ->orderBy('applied_at', 'desc')
            ->limit(50)
            ->get()
            ->map(function ($item) {
                return [
                    'id' => $item->id,
                    'applied_at' => $item->applied_at,
                    'user' => [
                        'id' => $item->user->id ?? null,
                        'name' => $item->user ? trim(($item->user->name ?? '') . ' ' . ($item->user->surname ?? '')) : 'Неизвестно',
                        'phone' => $item->user->phone ?? null,
                    ],
                    'referrer' => [
                        'id' => $item->referrer->id ?? null,
                        'name' => $item->referrer ? trim(($item->referrer->name ?? '') . ' ' . ($item->referrer->surname ?? '')) : 'Неизвестно',
                        'phone' => $item->referrer->phone ?? null,
                    ],
                ];
            });

        return response()->json([
            'success' => true,
            'data' => [
                // Основные метрики
                'total_applied' => $totalApplied,
                'total_applied_all_time' => $totalAppliedAllTime,
                'unique_referrers' => $uniqueReferrers,
                'new_referred_users' => $newReferredUsers,
                
                // Конверсия
                'referred_with_purchases' => $referredWithPurchases,
                'conversion_rate' => $conversionRate,
                
                // Статистика покупок
                'purchase_stats' => [
                    'total_purchases' => $purchaseStats->total_purchases ?? 0,
                    'total_amount' => $purchaseStats->total_amount ?? 0,
                ],
                
                // Подарки
                'gifts_to_referrers' => $giftsToReferrers,
                
                // Динамика
                'by_date' => $byDate,
                
                // Топ рефереров
                'top_referrers' => $topReferrers,
                
                // Последние применения
                'recent_applications' => $recentApplications,
                
                // Настройки акции
                'promotion' => $promotionSettings,
            ],
            'period' => [
                'start_date' => $startDate,
                'end_date' => $endDate,
            ],
        ]);
    }
}
