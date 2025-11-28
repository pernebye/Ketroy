<?php

namespace App\Services;

use App\Models\DeviceToken;
use App\Models\User;
use App\Models\LoyaltyLevel;
use App\Models\UserLoyaltyReward;
use App\Jobs\SendLoyaltyLevelUpPushJob;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Сервис управления уровнями лояльности
 * 
 * Проверяет и присваивает уровни лояльности пользователям
 * на основе их общей суммы покупок.
 */
class LoyaltyLevelService
{
    protected OneCApiService $oneCApi;

    public function __construct(OneCApiService $oneCApi)
    {
        $this->oneCApi = $oneCApi;
    }

    /**
     * Обработать покупку и проверить/присвоить уровень лояльности
     * 
     * Вызывается при получении webhook от 1С о новой покупке.
     * Присваивает ВСЕ достигнутые уровни, которых ещё нет у пользователя.
     * 
     * @param User $user Пользователь
     * @param int $totalPurchases Общая сумма покупок из 1С
     * @return array Результат обработки
     */
    public function processPurchase(User $user, int $totalPurchases): array
    {
        Log::info('[Loyalty] Processing purchase', [
            'user_id' => $user->id,
            'phone' => $user->phone,
            'total_purchases' => $totalPurchases,
        ]);

        // Получаем все активные уровни, которые пользователь достиг по сумме
        $achievedLevels = LoyaltyLevel::where('is_active', true)
            ->where('min_purchase_amount', '<=', $totalPurchases)
            ->orderBy('min_purchase_amount', 'asc')
            ->get();

        if ($achievedLevels->isEmpty()) {
            Log::info('[Loyalty] No levels achieved', ['user_id' => $user->id]);
            return [
                'levels_granted' => [],
                'highest_level' => null,
            ];
        }

        // Получаем уровни, которые уже были присвоены пользователю
        $existingLevelIds = UserLoyaltyReward::where('user_id', $user->id)
            ->pluck('loyalty_level_id')
            ->toArray();

        // Находим новые уровни (которые достигнуты, но ещё не присвоены)
        $newLevels = $achievedLevels->filter(function ($level) use ($existingLevelIds) {
            return !in_array($level->id, $existingLevelIds);
        });

        if ($newLevels->isEmpty()) {
            Log::info('[Loyalty] All achieved levels already granted', ['user_id' => $user->id]);
            return [
                'levels_granted' => [],
                'highest_level' => $achievedLevels->last(),
            ];
        }

        // Присваиваем все новые уровни
        $grantedLevels = [];
        $highestNewLevel = null;

        DB::beginTransaction();
        try {
            foreach ($newLevels as $level) {
                $this->grantLevel($user, $level);
                $grantedLevels[] = $level;
                $highestNewLevel = $level; // Последний = самый высокий (отсортировано по min_purchase_amount)
            }
            DB::commit();

            // Отправляем push только о самом высоком новом уровне
            if ($highestNewLevel) {
                $this->sendLevelUpNotification($user, $highestNewLevel, count($grantedLevels));
            }

            Log::info('[Loyalty] Levels granted', [
                'user_id' => $user->id,
                'granted_count' => count($grantedLevels),
                'highest_level' => $highestNewLevel->name,
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('[Loyalty] Error granting levels', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }

        return [
            'levels_granted' => $grantedLevels,
            'highest_level' => $achievedLevels->last(),
        ];
    }

    /**
     * Присвоить уровень пользователю и выдать награды
     */
    protected function grantLevel(User $user, LoyaltyLevel $level): UserLoyaltyReward
    {
        Log::info('[Loyalty] Granting level', [
            'user_id' => $user->id,
            'level_id' => $level->id,
            'level_name' => $level->name,
        ]);

        // Создаём запись о достижении уровня
        $userReward = UserLoyaltyReward::create([
            'user_id' => $user->id,
            'loyalty_level_id' => $level->id,
            'achieved_at' => now(),
        ]);

        // Выдаём награды за этот уровень
        foreach ($level->activeRewards as $reward) {
            $this->grantReward($user, $level, $reward, $userReward);
        }

        return $userReward;
    }

    /**
     * Выдать конкретную награду
     */
    protected function grantReward(User $user, LoyaltyLevel $level, $reward, UserLoyaltyReward $userReward): void
    {
        Log::info('[Loyalty] Granting reward', [
            'user_id' => $user->id,
            'reward_type' => $reward->reward_type,
        ]);

        switch ($reward->reward_type) {
            case 'discount':
                // Обновляем скидку в 1С
                $this->updateUserDiscount($user, $reward->discount_percent);
                break;

            case 'bonus':
                // Начисляем бонусы в 1С
                $this->addUserBonus($user, $reward->bonus_amount);
                break;

            case 'gift_choice':
                // Для подарка - связываем награду с записью пользователя
                // Пользователь выберет подарок позже в приложении
                $userReward->update([
                    'loyalty_level_reward_id' => $reward->id,
                ]);
                break;
        }
    }

    /**
     * Обновить скидку пользователя в 1С
     */
    protected function updateUserDiscount(User $user, int $discountPercent): void
    {
        $phone = str_replace('+7', '8', $user->country_code) . $user->phone;
        
        $result = $this->oneCApi->updateDiscount($phone, $discountPercent);
        
        if ($result) {
            // Обновляем локально
            $user->update(['discount' => $discountPercent]);
            Log::info('[Loyalty] Discount updated', [
                'user_id' => $user->id,
                'discount' => $discountPercent,
            ]);
        } else {
            Log::warning('[Loyalty] Failed to update discount in 1C', [
                'user_id' => $user->id,
                'discount' => $discountPercent,
            ]);
        }
    }

    /**
     * Начислить бонусы пользователю в 1С
     */
    protected function addUserBonus(User $user, int $bonusAmount): void
    {
        $phone = str_replace('+7', '8', $user->country_code) . $user->phone;
        
        $result = $this->oneCApi->updateBonus(
            $phone,
            $bonusAmount,
            'add', // операция начисления
            now()->format('Y-m-d\TH:i:s'),
            "Награда за достижение уровня лояльности",
            false // без отсрочки - бонусы доступны сразу
        );
        
        if ($result) {
            Log::info('[Loyalty] Bonus added', [
                'user_id' => $user->id,
                'bonus' => $bonusAmount,
            ]);
        } else {
            Log::warning('[Loyalty] Failed to add bonus in 1C', [
                'user_id' => $user->id,
                'bonus' => $bonusAmount,
            ]);
        }
    }

    /**
     * Отправить push-уведомление о новом уровне
     */
    protected function sendLevelUpNotification(User $user, LoyaltyLevel $level, int $levelsCount): void
    {
        // Проверяем наличие активного токена
        $activeToken = DeviceToken::getActiveTokenForUser($user->id);
        
        if (empty($activeToken)) {
            Log::info('[Loyalty] No active device token, skipping push', ['user_id' => $user->id]);
            return;
        }

        dispatch(new SendLoyaltyLevelUpPushJob($user, $level, $levelsCount));
    }

    /**
     * Получить текущую информацию о лояльности пользователя
     * (для отображения в приложении)
     */
    public function getUserLoyaltyInfo(User $user): array
    {
        // Получаем данные из 1С
        $phone = str_replace('+7', '8', $user->country_code) . $user->phone;
        $oneCData = $this->oneCApi->getClientInfo($phone);
        
        $purchaseSum = $oneCData['purchasesAmount'] ?? 0;

        // Текущий уровень (максимальный достигнутый)
        $currentLevel = UserLoyaltyReward::where('user_id', $user->id)
            ->with('loyaltyLevel')
            ->orderByDesc('achieved_at')
            ->first()
            ?->loyaltyLevel;

        // Все уровни для отображения прогресса
        $allLevels = LoyaltyLevel::where('is_active', true)
            ->orderBy('min_purchase_amount')
            ->with('activeRewards.giftOptions')
            ->get();

        // Следующий уровень
        $nextLevel = $allLevels
            ->where('min_purchase_amount', '>', $purchaseSum)
            ->first();

        // Прогресс до следующего уровня
        $progress = 0;
        if ($nextLevel && $currentLevel) {
            $currentThreshold = $currentLevel->min_purchase_amount;
            $nextThreshold = $nextLevel->min_purchase_amount;
            $range = $nextThreshold - $currentThreshold;
            $progressAmount = $purchaseSum - $currentThreshold;
            $progress = $range > 0 ? min(100, ($progressAmount / $range) * 100) : 0;
        } elseif ($nextLevel) {
            // Ещё нет уровня
            $progress = min(100, ($purchaseSum / $nextLevel->min_purchase_amount) * 100);
        } else {
            // Достигнут максимальный уровень
            $progress = 100;
        }

        // ID уровней, достигнутых пользователем
        $achievedLevelIds = UserLoyaltyReward::where('user_id', $user->id)
            ->pluck('loyalty_level_id')
            ->toArray();

        return [
            'current_level' => $currentLevel,
            'next_level' => $nextLevel,
            'purchase_sum' => $purchaseSum,
            'progress_percent' => round($progress, 1),
            'amount_to_next' => $nextLevel 
                ? max(0, $nextLevel->min_purchase_amount - $purchaseSum) 
                : 0,
            'all_levels' => $allLevels->map(function ($level) use ($achievedLevelIds) {
                return [
                    'id' => $level->id,
                    'name' => $level->name,
                    'icon' => $level->icon,
                    'color' => $level->color,
                    'min_purchase_amount' => $level->min_purchase_amount,
                    'is_achieved' => in_array($level->id, $achievedLevelIds),
                    'rewards' => $level->activeRewards,
                ];
            }),
        ];
    }

    /**
     * Получить награды, доступные для выбора (gift_choice)
     */
    public function getPendingGiftChoices(User $user): array
    {
        return UserLoyaltyReward::where('user_id', $user->id)
            ->whereNotNull('loyalty_level_reward_id')
            ->whereNull('selected_gift_id')
            ->whereNull('reward_claimed_at')
            ->with(['loyaltyLevel', 'reward.giftOptions'])
            ->get()
            ->toArray();
    }

    /**
     * Выбрать подарок из награды
     */
    public function selectGift(User $user, int $userRewardId, int $giftId): bool
    {
        $userReward = UserLoyaltyReward::where('id', $userRewardId)
            ->where('user_id', $user->id)
            ->whereNull('selected_gift_id')
            ->first();

        if (!$userReward) {
            return false;
        }

        // Проверяем, что подарок доступен в этой награде
        $reward = $userReward->reward;
        if (!$reward || !$reward->giftOptions()->where('gift_catalog.id', $giftId)->exists()) {
            return false;
        }

        $userReward->update([
            'selected_gift_id' => $giftId,
            'reward_claimed_at' => now(),
        ]);

        return true;
    }
}

