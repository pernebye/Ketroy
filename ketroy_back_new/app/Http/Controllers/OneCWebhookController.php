<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\LoyaltyLevelService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

/**
 * Контроллер для обработки webhook-ов от 1С
 */
class OneCWebhookController extends Controller
{
    protected LoyaltyLevelService $loyaltyService;

    public function __construct(LoyaltyLevelService $loyaltyService)
    {
        $this->loyaltyService = $loyaltyService;
    }

    /**
     * Обработать webhook о покупке от 1С
     * 
     * Вызывается 1С после каждой продажи.
     * Проверяет уровень лояльности и присваивает награды если нужно.
     * 
     * @OA\Post(
     *     path="/api/1c/purchase",
     *     summary="Webhook: Уведомление о покупке от 1С",
     *     description="Принимает данные о покупке от 1С и обрабатывает уровень лояльности",
     *     tags={"1C Webhooks"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"phone", "total_purchases"},
     *             @OA\Property(property="phone", type="string", example="87771234567"),
     *             @OA\Property(property="purchase_amount", type="integer", example=45000),
     *             @OA\Property(property="total_purchases", type="integer", example=520000),
     *             @OA\Property(property="timestamp", type="string", example="2024-11-27T10:15:32")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Webhook обработан успешно",
     *         @OA\JsonContent(
     *             @OA\Property(property="status", type="string", example="ok"),
     *             @OA\Property(property="levels_granted", type="integer", example=1),
     *             @OA\Property(property="highest_level", type="string", example="Серебро")
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Неверные данные запроса"
     *     )
     * )
     */
    public function handlePurchase(Request $request): JsonResponse
    {
        Log::info('[1C Webhook] Purchase received', $request->all());

        $validated = $request->validate([
            'phone' => 'required|string',
            'purchase_amount' => 'nullable|numeric|min:0',
            'total_purchases' => 'required|numeric|min:0',
            'timestamp' => 'nullable|string',
        ]);

        // Нормализуем телефон (убираем 8 в начале, оставляем 10 цифр)
        $phone = $this->normalizePhone($validated['phone']);

        // Ищем пользователя по телефону
        $user = User::where('phone', $phone)->first();

        if (!$user) {
            Log::info('[1C Webhook] User not found', ['phone' => $phone]);
            return response()->json([
                'status' => 'user_not_found',
                'message' => 'Пользователь с таким телефоном не найден в приложении',
            ], 200); // 200 чтобы 1С не ретраил
        }

        try {
            // Обрабатываем покупку и проверяем уровень
            $result = $this->loyaltyService->processPurchase(
                $user,
                (int) $validated['total_purchases']
            );

            $response = [
                'status' => 'ok',
                'user_id' => $user->id,
                'levels_granted' => count($result['levels_granted']),
            ];

            if ($result['highest_level']) {
                $response['highest_level'] = $result['highest_level']->name;
            }

            if (count($result['levels_granted']) > 0) {
                $response['new_levels'] = array_map(function ($level) {
                    return [
                        'id' => $level->id,
                        'name' => $level->name,
                    ];
                }, $result['levels_granted']);
            }

            Log::info('[1C Webhook] Purchase processed', $response);

            return response()->json($response);

        } catch (\Exception $e) {
            Log::error('[1C Webhook] Error processing purchase', [
                'phone' => $phone,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Ошибка обработки: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Нормализовать номер телефона
     * 
     * Преобразует различные форматы в 10-значный номер:
     * 87771234567 → 7771234567
     * +77771234567 → 7771234567
     * 77771234567 → 7771234567
     */
    protected function normalizePhone(string $phone): string
    {
        // Убираем все нецифровые символы
        $digits = preg_replace('/\D/', '', $phone);
        
        // Если начинается с 8 или 7 и длина 11 - убираем первую цифру
        if (strlen($digits) === 11 && in_array($digits[0], ['7', '8'])) {
            return substr($digits, 1);
        }
        
        // Если уже 10 цифр - возвращаем как есть
        if (strlen($digits) === 10) {
            return $digits;
        }
        
        return $digits;
    }

    /**
     * Health check для проверки доступности webhook
     */
    public function healthCheck(): JsonResponse
    {
        return response()->json([
            'status' => 'ok',
            'service' => '1C Webhook Handler',
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}


