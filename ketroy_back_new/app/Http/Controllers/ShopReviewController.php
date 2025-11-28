<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\ShopReview;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;

class ShopReviewController extends Controller
{

    /**
     * @OA\Post(
     *     path="/reviews",
     *     summary="Добавление или обновление отзыва о магазине",
     *     description="Создает новый отзыв или обновляет существующий (один пользователь = один отзыв на магазин).",
     *     tags={"ShopReviews"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"shop_id", "user_id", "review", "rating"},
     *             @OA\Property(property="shop_id", type="integer"),
     *             @OA\Property(property="user_id", type="integer"),
     *             @OA\Property(property="review", type="string"),
     *             @OA\Property(property="rating", type="number", format="float", minimum=0, maximum=5)
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Отзыв успешно добавлен",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Отзыв успешно добавлен!"),
     *             @OA\Property(property="is_new", type="boolean", example=true)
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Отзыв успешно обновлён",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Отзыв успешно обновлён!"),
     *             @OA\Property(property="is_new", type="boolean", example=false)
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Ошибка валидации"
     *     )
     * )
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'shop_id' => 'required|exists:shops,id',
            'user_id' => 'required|exists:users,id',
            'review' => 'required|string',
            'rating' => 'required|numeric|min:0|max:5',
        ]);

        // Проверяем, есть ли уже отзыв от этого пользователя на этот магазин
        $existingReview = ShopReview::where('user_id', $validated['user_id'])
            ->where('shop_id', $validated['shop_id'])
            ->first();

        if ($existingReview) {
            // Обновляем существующий отзыв
            $existingReview->update([
                'review' => $validated['review'],
                'rating' => $validated['rating'],
                'is_edited' => true,
                'edited_at' => Carbon::now(),
                'updated_at' => Carbon::now(), // Обновляем дату для сортировки как "новый"
            ]);

            return response()->json([
                'message' => 'Отзыв успешно обновлён!',
                'is_new' => false,
                'review' => $existingReview->fresh()->load(['shop', 'user'])
            ], 200);
        }

        // Создаём новый отзыв
        $review = ShopReview::create($validated);

        return response()->json([
            'message' => 'Отзыв успешно добавлен!',
            'is_new' => true,
            'review' => $review->load(['shop', 'user'])
        ], 201);
    }

    /**
     * @OA\Get(
     *     path="/reviews/check/{shopId}/{userId}",
     *     summary="Проверка наличия отзыва пользователя на магазин",
     *     description="Возвращает существующий отзыв пользователя или null",
     *     tags={"ShopReviews"},
     *     @OA\Parameter(name="shopId", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\Parameter(name="userId", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\Response(
     *         response=200,
     *         description="Результат проверки"
     *     )
     * )
     */
    public function checkUserReview($shopId, $userId): JsonResponse
    {
        $review = ShopReview::where('shop_id', $shopId)
            ->where('user_id', $userId)
            ->first();

        return response()->json([
            'has_review' => $review !== null,
            'review' => $review
        ]);
    }

    /**
     * @OA\Get(
     *     path="/reviews",
     *     summary="Получение всех отзывов о магазинах",
     *     description="Возвращает список всех отзывов о магазинах, отсортированных по дате (новые/обновлённые первыми).",
     *     tags={"ShopReviews"},
     *     @OA\Response(
     *         response=200,
     *         description="Список отзывов",
     *         @OA\JsonContent(
     *             type="array",
     *             @OA\Items(
     *                 type="object",
     *                 @OA\Property(property="id", type="integer"),
     *                 @OA\Property(property="shop_id", type="integer"),
     *                 @OA\Property(property="user_id", type="integer"),
     *                 @OA\Property(property="review", type="string"),
     *                 @OA\Property(property="rating", type="number"),
     *                 @OA\Property(property="is_edited", type="boolean"),
     *                 @OA\Property(property="edited_at", type="string", format="datetime"),
     *                 @OA\Property(property="shop", type="object",
     *                     @OA\Property(property="id", type="integer"),
     *                     @OA\Property(property="name", type="string"),
     *                     @OA\Property(property="city", type="string"),
     *                     @OA\Property(property="type", type="string")
     *                 ),
     *                 @OA\Property(property="user", type="object",
     *                     @OA\Property(property="id", type="integer"),
     *                     @OA\Property(property="name", type="string")
     *                 ),
     *             )
     *         )
     *     )
     * )
     */
    public function getAllReviews(Request $request): JsonResponse
    {
        $reviews = ShopReview::with(['shop', 'user'])
            ->when($request->input('shop_id'), function ($query) use ($request) {
                return $query->where('shop_id', $request->input('shop_id'));
            })
            ->orderBy('updated_at', 'desc') // Новые и обновлённые первыми
            ->get();

        return response()->json($reviews);
    }

    /**
     * @OA\Delete(
     *     path="/reviews/{id}",
     *     summary="Удаление отзыва",
     *     description="Удаляет отзыв по указанному идентификатору.",
     *     tags={"ShopReviews"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="ID отзыва",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Отзыв успешно удалён",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Отзыв успешно удалён")
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Отзыв не найден"
     *     )
     * )
     */
    public function deleteReview($id): JsonResponse
    {
        $review = ShopReview::findOrFail($id);  // Найти отзыв или вернуть 404

        $review->delete();  // Удалить отзыв

        return response()->json(['message' => 'Отзыв успешно удалён']);
    }
}
