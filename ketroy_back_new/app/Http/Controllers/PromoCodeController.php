<?php

namespace App\Http\Controllers;

use App\Events\UserInteractionEvent;
use App\Services\ReferralService;
use Illuminate\Http\Request;
use App\Models\PromoCode;
use App\Services\OneCApiService;
use Illuminate\Support\Facades\Cache;

class PromoCodeController extends Controller
{
    protected OneCApiService $oneCApi;
    protected ReferralService $referralService;

    public function __construct(OneCApiService $oneCApi, ReferralService $referralService)
    {
        $this->oneCApi = $oneCApi;
        $this->referralService = $referralService;
    }

    /**
     * @OA\Post(
     *     path="/promo-codes/apply",
     *     summary="Применение промокода",
     *     description="Пользователь может применить промокод для получения скидки и бонусов для реферера.",
     *     tags={"PromoCodes"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"promo_code"},
     *             @OA\Property(property="promo_code", type="string", example="SUMMER2024")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Промокод успешно применён",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Промокод успешно применён")
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Ошибка применения промокода (например, промокод уже использован или не существует)",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Вы уже использовали промокод")
     *         )
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Ошибка валидации данных",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="The given data was invalid.")
     *         )
     *     )
     * )
     */
    public function applyPromoCode(Request $request)
    {
        $request->validate([
            'promo_code' => 'required|string|exists:promo_codes,code',
        ]);

        // Проверяем, доступна ли реферальная программа
        if (!$this->referralService->isAvailable()) {
            return response()->json([
                'message' => 'Реферальная программа временно недоступна'
            ], 400);
        }

        $promoCode = PromoCode::where('code', $request->promo_code)->firstOrFail();
        $referrer = $promoCode->user;
        $user = $request->user();

        if ($referrer->id == $user->id) {
            return response()->json(['message' => 'Вы не можете использовать свой промокод'], 403);
        }

        // Проверяем, чтобы пользователь не использовал промокоды ранее
        if ($user->used_promo_code) {
            return response()->json(['message' => 'Вы уже использовали промокод'], 400);
        }

        event(new UserInteractionEvent("promo_code_use", "", $user));

        // Применяем промокод через сервис
        $result = $this->referralService->applyPromoCode($user, $referrer);

        if (!$result['success']) {
            return response()->json(['message' => $result['message']], 400);
        }

        return response()->json([
            'message' => $result['message'],
            'discount_percent' => $result['discount_percent'] ?? null
        ], 200);
    }

    /**
     * @OA\Post(
     *     path="/api/referral/generate",
     *     summary="Генерация реферальной ссылки",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             @OA\Property(property="user_id", type="integer", example=1)
     *         )
     *     ),
     *     @OA\Response(response=200, description="Ссылка создана")
     * )
     */
    public function generate(Request $request)
    {
        $user = $request->user();
        return response()->json([
            'short_url' => url("/r/{$user->promoCode()}")
        ]);
    }

    /**
     * @OA\Post(
     *     path="/api/referral/consume",
     *     summary="Применить реферальную ссылку",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             @OA\Property(property="token", type="string", example="uuid-token")
     *         )
     *     ),
     *     @OA\Response(response=200, description="Реферал применен")
     * )
     */
    public function consume(Request $request)
    {
        $request->validate(['token' => 'required|string']);
        
        // Проверяем, доступна ли реферальная программа
        if (!$this->referralService->isAvailable()) {
            return response()->json([
                'message' => 'Реферальная программа временно недоступна'
            ], 400);
        }

        $referrerId = Cache::pull("referral_{$request->token}");

        $user = $request->user();
        if (!$referrerId || $user->id == $referrerId) {
            return response()->json(['message' => 'Недействительный токен'], 404);
        }

        // Проверяем, чтобы пользователь не использовал промокоды ранее
        if ($user->used_promo_code) {
            return response()->json(['message' => 'Вы уже использовали промокод'], 400);
        }

        $referrer = \App\Models\User::find($referrerId);
        if (!$referrer) {
            return response()->json(['message' => 'Реферер не найден'], 404);
        }

        event(new UserInteractionEvent("promo_code_use", "", $user));

        // Применяем промокод через сервис
        $result = $this->referralService->applyPromoCode($user, $referrer);

        if (!$result['success']) {
            return response()->json(['message' => $result['message']], 400);
        }

        return response()->json([
            'message' => 'Реферал применен',
            'discount_percent' => $result['discount_percent'] ?? null
        ]);
    }

    /**
     * Получить информацию о реферальной программе для мобильного приложения
     */
    public function getReferralInfo(Request $request)
    {
        $user = $request->user();
        $info = $this->referralService->getInfoForMobile($user);
        
        return response()->json($info);
    }
}
