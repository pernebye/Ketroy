<?php

namespace App\Http\Controllers;

use App\Events\UserInteractionEvent;
use App\Models\User;
use Illuminate\Http\Request;
use App\Services\OneCApiService;
use SimpleSoftwareIO\QrCode\Facades\QrCode;

class BonusCardController extends Controller
{
    protected $oneCApi;

    public function __construct(OneCApiService $oneCApi)
    {
        $this->oneCApi = $oneCApi;
    }
    /**
     * @OA\Get(
     *     path="/bonus-card",
     *     summary="Получение бонусных данных пользователя",
     *     description="Позволяет получить бонусные данные пользователя на основе его номера телефона.",
     *     tags={"User Management"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Response(
     *         response=200,
     *         description="Бонусные данные успешно получены",
     *         @OA\JsonContent(
     *             type="object",
     *             additionalProperties=true,
     *             example={"bonus_points": 150}
     *         )
     *     ),
     * )
     */
    public function show(Request $request)
    {
        $user = $request->user();

        $bonusData = $this->oneCApi->getClientInfo(str_replace('+7', '8', $user->country_code) . $user->phone);

        if (!$bonusData) {
            return response()->json(null);
        }

        return response()->json(['bonus_points' => $bonusData['bonusAmount']]);
    }

    /**
     * @OA\Get(
     *     path="/static-discount-qrcode",
     *     summary="Генерация QR-кода для скидки",
     *     description="Генерирует QR-код, который можно использовать для получения скидки. QR-код содержит ссылку на страницу скидки.",
     *     tags={"Discounts"},
     *     @OA\Response(
     *         response=200,
     *         description="QR-код для скидки успешно сгенерирован",
     *         @OA\MediaType(
     *             mediaType="image/svg+xml",
     *             @OA\Schema(type="string", format="binary")
     *         )
     *     )
     * )
     */
    public function generateDiscountQrCode()
    {

        $url = route('scan-discount');
        $qrCode = QrCode::size(300)->generate($url);

        return response($qrCode)->header('Content-Type', 'image/svg+xml');
    }

    /**
     * @OA\Post(
     *     path="/scan-discount",
     *     summary="Активация скидки с помощью токена",
     *     description="Генерирует временный токен для активации скидки для пользователя. Токен действителен 10 минут.",
     *     tags={"Discounts"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Response(
     *         response=200,
     *         description="Скидка успешно активирована",
     *         @OA\JsonContent(
     *             @OA\Property(property="discount", type="number", example=20),
     *             @OA\Property(property="message", type="string", example="Скидка активирована!"),
     *             @OA\Property(property="token", type="string", example="5e884898da28047151d0e56f8dc1f74e3b2f16b2"),
     *             @OA\Property(property="expires_in", type="integer", example=10)
     *         )
     *     )
     * )
     */
    public function scanDiscount(Request $request)
    {
        $user = $request->user();
        $token = bin2hex(random_bytes(16));

        if (!$user) {
            return response()->json(['message' => 'Необходима авторизация.'], 401);
        }

        // Генерация временного токена
        $qrToken = bin2hex(random_bytes(16));
        cache()->put("discount_{$qrToken}", $user->phone, now()->addMinutes(10));
        event(new UserInteractionEvent("qr_scanned", "", $user));

        cache()->forget("discount_qr_{$token}");

        $discountOneC = $this->oneCApi->getClientInfo(str_replace('+7', '8', $user->country_code) . $user->phone);
        if ($discountOneC) {
            $discount = $discountOneC['personalDiscount'];
        } else {
            $discount = 0;
        }

        return response()->json([
            'discount' => $discount,
            'message' => 'Скидка активирована!',
            'token' => $qrToken,
            'expires_in' => 10,
        ]);
    }

    /**
     * @OA\Post(
     *     path="/verify-discount",
     *     summary="Проверка действительности токена скидки",
     *     description="Проверяет, действителен ли токен скидки, и активирует персональную скидку для пользователя, если токен действителен.",
     *     tags={"Discounts"},
     *     @OA\Parameter(
     *         name="token",
     *         in="query",
     *         description="Токен скидки, полученный при активации скидки.",
     *         required=true,
     *         @OA\Schema(
     *             type="string",
     *             example="5e884898da28047151d0e56f8dc1f74e3b2f16b2"
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Персональная скидка успешно активирована",
     *         @OA\JsonContent(
     *             @OA\Property(property="discount", type="number", example=20),
     *             @OA\Property(property="message", type="string", example="Персональная скидка активирована")
     *         )
     *     )
     * )
     */
    public function verifyDiscount(Request $request)
    {
        $token = $request->token;
        $userPhone = cache()->get("discount_{$token}");

        if (!$userPhone) {
            return response()->json(['message' => 'Токен недействителен или истёк'], 403);
        }

        $user = $request->user();

        $discount = $this->oneCApi->getClientInfo(str_replace('+7', '8', $user->country_code) . $user->phone);

        if (!$discount) {
            return response()->json([
                'discount' => NULL,
                'message' => 'Персональная скидка не найдена',
            ]);
        }

        return response()->json([
            'discount' => $discount['personalDiscount'],
            'message' => 'Персональная скидка активна',
        ]);
    }
}
