<?php

namespace App\Http\Controllers;

use App\Models\LoyaltyLevel;
use App\Models\LoyaltyLevelReward;
use App\Models\GiftCatalog;
use App\Services\LoyaltyLevelService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class LoyaltyLevelController extends Controller
{
    protected LoyaltyLevelService $loyaltyService;

    public function __construct(LoyaltyLevelService $loyaltyService)
    {
        $this->loyaltyService = $loyaltyService;
    }
    /**
     * Получить все уровни лояльности с наградами
     */
    public function index(): JsonResponse
    {
        $levels = LoyaltyLevel::with(['rewards.giftOptions'])
            ->orderBy('order')
            ->orderBy('min_purchase_amount')
            ->get();

        return response()->json($levels);
    }

    /**
     * Получить один уровень
     */
    public function show($id): JsonResponse
    {
        $level = LoyaltyLevel::with(['rewards.giftOptions'])->findOrFail($id);
        return response()->json($level);
    }

    /**
     * Создать новый уровень лояльности
     */
    public function store(Request $request): JsonResponse
    {
        Log::info('[LoyaltyLevel Store] Creating new level', $request->all());

        $request->validate([
            'name' => 'required|string|max:255',
            'icon' => 'nullable|string|max:50',
            'color' => 'nullable|string|max:7',
            'min_purchase_amount' => 'required|integer|min:0',
            'order' => 'nullable|integer|min:0',
            'rewards' => 'nullable|array',
            'rewards.*.reward_type' => 'required_with:rewards|in:discount,bonus,gift_choice',
            'rewards.*.discount_percent' => 'nullable|integer|min:0|max:100',
            'rewards.*.bonus_amount' => 'nullable|integer|min:0',
            'rewards.*.description' => 'nullable|string|max:255',
            'rewards.*.gift_ids' => 'nullable|array',
            'rewards.*.gift_ids.*' => 'exists:gift_catalog,id',
        ]);

        try {
            DB::beginTransaction();

            // Автоматически определяем порядок если не указан
            $order = $request->order ?? (LoyaltyLevel::max('order') + 1);

            $level = LoyaltyLevel::create([
                'name' => $request->name,
                'icon' => $request->icon,
                'color' => $request->color,
                'min_purchase_amount' => $request->min_purchase_amount,
                'order' => $order,
                'is_active' => true,
            ]);

            // Создаём награды
            if ($request->has('rewards') && is_array($request->rewards)) {
                foreach ($request->rewards as $rewardData) {
                    $reward = $level->rewards()->create([
                        'reward_type' => $rewardData['reward_type'],
                        'discount_percent' => $rewardData['discount_percent'] ?? null,
                        'bonus_amount' => $rewardData['bonus_amount'] ?? null,
                        'description' => $rewardData['description'] ?? null,
                        'is_active' => true,
                    ]);

                    // Привязываем подарки для gift_choice
                    if ($rewardData['reward_type'] === 'gift_choice' && !empty($rewardData['gift_ids'])) {
                        $reward->giftOptions()->sync($rewardData['gift_ids']);
                    }
                }
            }

            DB::commit();

            return response()->json([
                'message' => 'Уровень лояльности создан',
                'level' => $level->load(['rewards.giftOptions'])
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('[LoyaltyLevel Store] Error: ' . $e->getMessage());
            return response()->json([
                'message' => 'Ошибка создания уровня: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Обновить уровень лояльности
     */
    public function update(Request $request, $id): JsonResponse
    {
        Log::info('[LoyaltyLevel Update] Updating level ' . $id, $request->all());

        $request->validate([
            'name' => 'required|string|max:255',
            'icon' => 'nullable|string|max:50',
            'color' => 'nullable|string|max:7',
            'min_purchase_amount' => 'required|integer|min:0',
            'order' => 'nullable|integer|min:0',
            'is_active' => 'nullable|boolean',
            'rewards' => 'nullable|array',
            'rewards.*.id' => 'nullable|exists:loyalty_level_rewards,id',
            'rewards.*.reward_type' => 'required_with:rewards|in:discount,bonus,gift_choice',
            'rewards.*.discount_percent' => 'nullable|integer|min:0|max:100',
            'rewards.*.bonus_amount' => 'nullable|integer|min:0',
            'rewards.*.description' => 'nullable|string|max:255',
            'rewards.*.gift_ids' => 'nullable|array',
            'rewards.*.gift_ids.*' => 'exists:gift_catalog,id',
            'rewards.*.is_active' => 'nullable|boolean',
        ]);

        try {
            DB::beginTransaction();

            $level = LoyaltyLevel::findOrFail($id);

            $level->update([
                'name' => $request->name,
                'icon' => $request->icon,
                'color' => $request->color,
                'min_purchase_amount' => $request->min_purchase_amount,
                'order' => $request->order ?? $level->order,
                'is_active' => $request->is_active ?? $level->is_active,
            ]);

            // Обновляем награды
            if ($request->has('rewards') && is_array($request->rewards)) {
                $existingRewardIds = [];

                foreach ($request->rewards as $rewardData) {
                    if (isset($rewardData['id'])) {
                        // Обновляем существующую награду
                        $reward = LoyaltyLevelReward::find($rewardData['id']);
                        if ($reward && $reward->loyalty_level_id === $level->id) {
                            $reward->update([
                                'reward_type' => $rewardData['reward_type'],
                                'discount_percent' => $rewardData['discount_percent'] ?? null,
                                'bonus_amount' => $rewardData['bonus_amount'] ?? null,
                                'description' => $rewardData['description'] ?? null,
                                'is_active' => $rewardData['is_active'] ?? true,
                            ]);
                            $existingRewardIds[] = $reward->id;
                        }
                    } else {
                        // Создаём новую награду
                        $reward = $level->rewards()->create([
                            'reward_type' => $rewardData['reward_type'],
                            'discount_percent' => $rewardData['discount_percent'] ?? null,
                            'bonus_amount' => $rewardData['bonus_amount'] ?? null,
                            'description' => $rewardData['description'] ?? null,
                            'is_active' => $rewardData['is_active'] ?? true,
                        ]);
                        $existingRewardIds[] = $reward->id;
                    }

                    // Обновляем подарки для gift_choice
                    if ($rewardData['reward_type'] === 'gift_choice') {
                        $reward->giftOptions()->sync($rewardData['gift_ids'] ?? []);
                    } else {
                        $reward->giftOptions()->sync([]);
                    }
                }

                // Удаляем награды, которых нет в запросе
                $level->rewards()->whereNotIn('id', $existingRewardIds)->delete();
            }

            DB::commit();

            return response()->json([
                'message' => 'Уровень лояльности обновлён',
                'level' => $level->load(['rewards.giftOptions'])
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('[LoyaltyLevel Update] Error: ' . $e->getMessage());
            return response()->json([
                'message' => 'Ошибка обновления уровня: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Удалить уровень лояльности
     */
    public function destroy($id): JsonResponse
    {
        $level = LoyaltyLevel::findOrFail($id);

        // Проверяем, есть ли пользователи с наградами за этот уровень
        $hasUserRewards = $level->userRewards()->exists();

        if ($hasUserRewards) {
            // Деактивируем вместо удаления
            $level->update(['is_active' => false]);
            return response()->json([
                'message' => 'Уровень деактивирован (есть пользователи с наградами)'
            ]);
        }

        // Удаляем полностью
        $level->delete();

        return response()->json([
            'message' => 'Уровень лояльности удалён'
        ]);
    }

    /**
     * Изменить порядок уровней
     */
    public function reorder(Request $request): JsonResponse
    {
        $request->validate([
            'levels' => 'required|array',
            'levels.*.id' => 'required|exists:loyalty_levels,id',
            'levels.*.order' => 'required|integer|min:0',
        ]);

        try {
            DB::beginTransaction();

            foreach ($request->levels as $levelData) {
                LoyaltyLevel::where('id', $levelData['id'])
                    ->update(['order' => $levelData['order']]);
            }

            DB::commit();

            return response()->json([
                'message' => 'Порядок уровней обновлён'
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Ошибка изменения порядка: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Получить доступные подарки для выбора
     */
    public function getAvailableGifts(): JsonResponse
    {
        $gifts = GiftCatalog::where('is_active', true)
            ->orderBy('name')
            ->get();

        return response()->json($gifts);
    }

    /**
     * Получить информацию о лояльности текущего пользователя
     * 
     * @OA\Get(
     *     path="/api/user/loyalty",
     *     summary="Информация о лояльности пользователя",
     *     description="Возвращает текущий уровень, прогресс и все доступные уровни",
     *     tags={"User Loyalty"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Response(
     *         response=200,
     *         description="Информация о лояльности"
     *     )
     * )
     */
    public function getUserLoyaltyInfo(Request $request): JsonResponse
    {
        $user = $request->user();
        $info = $this->loyaltyService->getUserLoyaltyInfo($user);

        return response()->json($info);
    }

    /**
     * Получить подарки, ожидающие выбора
     */
    public function getPendingGiftChoices(Request $request): JsonResponse
    {
        $user = $request->user();
        $pendingGifts = $this->loyaltyService->getPendingGiftChoices($user);

        return response()->json($pendingGifts);
    }

    /**
     * Выбрать подарок из награды
     */
    public function selectGift(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'user_reward_id' => 'required|integer|exists:user_loyalty_rewards,id',
            'gift_id' => 'required|integer|exists:gift_catalogs,id',
        ]);

        $user = $request->user();
        $success = $this->loyaltyService->selectGift(
            $user,
            $validated['user_reward_id'],
            $validated['gift_id']
        );

        if (!$success) {
            return response()->json([
                'message' => 'Не удалось выбрать подарок. Возможно, он уже выбран или недоступен.',
            ], 400);
        }

        return response()->json([
            'message' => 'Подарок успешно выбран!',
        ]);
    }
}




