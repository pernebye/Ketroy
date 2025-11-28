<?php

namespace App\Http\Controllers;

use App\Services\LotteryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LotteryController extends Controller
{
    protected LotteryService $lotteryService;

    public function __construct(LotteryService $lotteryService)
    {
        $this->lotteryService = $lotteryService;
    }

    /**
     * @OA\Get(
     *     path="/api/lottery/check",
     *     summary="Проверить активную лотерею при входе в приложение",
     *     description="Возвращает информацию об активной лотерее, если пользователь еще не участвовал",
     *     tags={"Лотерея"},
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="Информация о лотерее",
     *         @OA\JsonContent(
     *             @OA\Property(property="has_active_lottery", type="boolean", example=true),
     *             @OA\Property(property="lottery", type="object", nullable=true,
     *                 @OA\Property(property="promotion_id", type="integer", example=1),
     *                 @OA\Property(property="modal_title", type="string", example="Поздравляем! 🎉"),
     *                 @OA\Property(property="modal_text", type="string", example="Вы получили подарок!"),
     *                 @OA\Property(property="modal_image", type="string", nullable=true),
     *                 @OA\Property(property="modal_button_text", type="string", example="Получить подарок"),
     *                 @OA\Property(property="gifts_count", type="integer", example=3)
     *             )
     *         )
     *     ),
     *     @OA\Response(response=401, description="Не авторизован")
     * )
     */
    public function check(Request $request): JsonResponse
    {
        $user = $request->user();
        
        if (!$user) {
            return response()->json([
                'has_active_lottery' => false,
                'lottery' => null,
            ]);
        }

        $lotteryData = $this->lotteryService->getActiveLotteryForUser($user);

        return response()->json([
            'has_active_lottery' => $lotteryData !== null,
            'lottery' => $lotteryData,
        ]);
    }

    /**
     * @OA\Post(
     *     path="/api/lottery/claim",
     *     summary="Получить подарок лотереи",
     *     description="Создает группу подарков для пользователя и возвращает их для выбора",
     *     tags={"Лотерея"},
     *     security={{"bearerAuth":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             @OA\Property(property="promotion_id", type="integer", example=1)
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Подарок получен",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Подарок успешно получен!"),
     *             @OA\Property(property="gift_group_id", type="string", example="uuid"),
     *             @OA\Property(property="gifts", type="array",
     *                 @OA\Items(
     *                     @OA\Property(property="id", type="integer"),
     *                     @OA\Property(property="name", type="string"),
     *                     @OA\Property(property="image", type="string", nullable=true)
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(response=400, description="Ошибка"),
     *     @OA\Response(response=401, description="Не авторизован")
     * )
     */
    public function claim(Request $request): JsonResponse
    {
        $request->validate([
            'promotion_id' => 'required|integer|exists:promotions,id',
        ]);

        $user = $request->user();
        $result = $this->lotteryService->claimLotteryGift($user, $request->promotion_id);

        if (!$result['success']) {
            return response()->json($result, 400);
        }

        return response()->json($result);
    }

    /**
     * @OA\Post(
     *     path="/api/lottery/dismiss",
     *     summary="Закрыть модальное окно без получения подарка",
     *     description="Отмечает, что пользователь видел модальное окно",
     *     tags={"Лотерея"},
     *     security={{"bearerAuth":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             @OA\Property(property="promotion_id", type="integer", example=1)
     *         )
     *     ),
     *     @OA\Response(response=200, description="OK"),
     *     @OA\Response(response=401, description="Не авторизован")
     * )
     */
    public function dismiss(Request $request): JsonResponse
    {
        $request->validate([
            'promotion_id' => 'required|integer|exists:promotions,id',
        ]);

        $user = $request->user();
        $this->lotteryService->markModalShown($user, $request->promotion_id);

        return response()->json(['message' => 'OK']);
    }
}

