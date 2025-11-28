<?php

namespace App\Services;

use App\Jobs\SendReferralAppliedPushJob;
use App\Models\Gift;
use App\Models\Promotion;
use App\Models\PromotionGift;
use App\Models\Purchase;
use App\Models\User;
use App\Models\UserReferralReward;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ReferralService
{
    protected OneCApiService $oneCApi;

    public function __construct(OneCApiService $oneCApi)
    {
        $this->oneCApi = $oneCApi;
    }

    /**
     * Получить активную акцию "Подари скидку другу"
     */
    public function getActivePromotion(): ?Promotion
    {
        return Promotion::where('type', 'friend_discount')
            ->where('is_archived', false)
            ->where('is_active', true)
            ->with('gifts.giftCatalog')
            ->first();
    }

    /**
     * Проверить, доступна ли реферальная программа
     */
    public function isAvailable(): bool
    {
        return $this->getActivePromotion() !== null;
    }

    /**
     * Получить настройки реферальной программы
     */
    public function getSettings(): array
    {
        $promotion = $this->getActivePromotion();
        
        if (!$promotion) {
            return [];
        }

        $settings = is_array($promotion->settings) 
            ? $promotion->settings 
            : json_decode($promotion->settings, true);

        // Дефолтные значения если не заданы
        return [
            // Для реферера (владельца промокода)
            'referrer_bonus_percent' => $settings['referrer_bonus_percent'] ?? 2,
            'referrer_max_purchases' => $settings['referrer_max_purchases'] ?? 3,
            'referrer_high_discount_threshold' => $settings['referrer_high_discount_threshold'] ?? 30,
            
            // Для нового пользователя (использующего промокод)
            'new_user_discount_percent' => $settings['new_user_discount_percent'] ?? 10,
            'new_user_bonus_percent' => $settings['new_user_bonus_percent'] ?? 5,
            'new_user_bonus_purchases' => $settings['new_user_bonus_purchases'] ?? 1,
            
            // Подарки (для рефереров с высокой скидкой)
            'gifts' => $promotion->gifts->pluck('gift_catalog_id')->toArray(),
            
            // Метаданные акции
            'promotion_id' => $promotion->id,
            'promotion_name' => $promotion->name,
        ];
    }

    /**
     * Применить промокод для нового пользователя
     */
    public function applyPromoCode(User $newUser, User $referrer): array
    {
        $promotion = $this->getActivePromotion();
        
        if (!$promotion) {
            return [
                'success' => false,
                'message' => 'Реферальная программа временно недоступна'
            ];
        }

        // === ЗАЩИТА ОТ ВЗАИМНОГО ОБМЕНА ПРОМОКОДАМИ ===
        // Проверяем, не является ли реферер рефералом текущего пользователя
        // (т.е. текущий пользователь ранее привёл этого реферера)
        if ($referrer->referrer_id === $newUser->id) {
            Log::warning("[Referral] Mutual referral attempt blocked: user {$newUser->id} tried to use code from their own referral {$referrer->id}");
            return [
                'success' => false,
                'message' => 'Нельзя использовать промокод человека, которого вы сами пригласили'
            ];
        }

        // Дополнительная проверка: нельзя использовать промокод, если реферер уже использовал ваш
        $mutualReferral = UserReferralReward::where('user_id', $referrer->id)
            ->where('referrer_id', $newUser->id)
            ->exists();
            
        if ($mutualReferral) {
            Log::warning("[Referral] Mutual referral attempt blocked (via reward record): user {$newUser->id} <-> referrer {$referrer->id}");
            return [
                'success' => false,
                'message' => 'Взаимный обмен промокодами недоступен'
            ];
        }

        $settings = $this->getSettings();

        // Присваиваем скидку новому пользователю
        $discountPercent = $settings['new_user_discount_percent'];
        
        $newUser->update([
            'referrer_id' => $referrer->id,
            'used_promo_code' => true,
            'discount' => $discountPercent,
        ]);

        // Обновляем скидку в 1С
        try {
            $this->oneCApi->updateDiscount($newUser->fullPhone, $discountPercent);
        } catch (\Exception $e) {
            Log::error('[Referral] Failed to update discount in 1C: ' . $e->getMessage());
        }

        // Записываем информацию о применении с версией настроек
        UserReferralReward::create([
            'user_id' => $newUser->id,
            'referrer_id' => $referrer->id,
            'promotion_id' => $promotion->id,
            'settings_snapshot' => $settings, // Сохраняем настройки на момент применения
            'applied_at' => now(),
        ]);

        Log::info("[Referral] Promo code applied: user {$newUser->id} -> referrer {$referrer->id}, discount {$discountPercent}%");

        // Отправляем push-уведомление рефереру о том, что его промокод применён
        SendReferralAppliedPushJob::dispatch($referrer->id, $newUser->id);

        return [
            'success' => true,
            'message' => 'Промокод успешно применён',
            'discount_percent' => $discountPercent
        ];
    }

    /**
     * Обработать покупку реферала и начислить бонусы/подарки рефереру
     */
    public function processReferralPurchase(User $referredUser, int $purchaseAmount): void
    {
        $referrer = User::find($referredUser->referrer_id);
        
        if (!$referrer) {
            return;
        }

        // Получаем настройки из записи UserReferralReward (сохранённые на момент применения промокода)
        $rewardRecord = UserReferralReward::where('user_id', $referredUser->id)
            ->where('referrer_id', $referrer->id)
            ->first();

        if (!$rewardRecord) {
            Log::warning("[Referral] No reward record found for user {$referredUser->id}");
            return;
        }

        $settings = $rewardRecord->settings_snapshot;
        
        if (!$settings) {
            // Fallback на текущие настройки
            $settings = $this->getSettings();
        }

        // Считаем количество покупок реферала
        $purchaseCount = Purchase::where('user_id', $referredUser->id)->count();

        Log::info("[Referral] Processing purchase #{$purchaseCount} for referred user {$referredUser->id}, referrer {$referrer->id}");

        // Проверяем, не превышен ли лимит покупок
        $maxPurchases = $settings['referrer_max_purchases'] ?? 3;
        if ($purchaseCount > $maxPurchases) {
            Log::info("[Referral] Max purchases exceeded ({$purchaseCount} > {$maxPurchases})");
            return;
        }

        // Проверяем скидку реферера
        $highDiscountThreshold = $settings['referrer_high_discount_threshold'] ?? 30;

        if ($referrer->discount >= $highDiscountThreshold) {
            // Реферер с высокой скидкой - получает подарок вместо бонусов
            $this->grantGiftToReferrer($referrer, $rewardRecord->promotion_id);
        } else {
            // Обычный реферер - получает бонусы
            $bonusPercent = $settings['referrer_bonus_percent'] ?? 2;
            $bonusAmount = round($purchaseAmount * ($bonusPercent / 100));
            
            if ($bonusAmount > 0) {
                $this->grantBonusToReferrer($referrer, $bonusAmount);
            }
        }

        // Также начисляем бонусы новому пользователю за его первые покупки
        $newUserBonusPurchases = $settings['new_user_bonus_purchases'] ?? 1;
        $newUserBonusPercent = $settings['new_user_bonus_percent'] ?? 5;
        
        if ($purchaseCount <= $newUserBonusPurchases && $newUserBonusPercent > 0) {
            $newUserBonus = round($purchaseAmount * ($newUserBonusPercent / 100));
            if ($newUserBonus > 0) {
                $this->grantBonusToUser($referredUser, $newUserBonus);
            }
        }
    }

    /**
     * Начислить бонусы рефереру
     */
    protected function grantBonusToReferrer(User $referrer, int $bonusAmount): void
    {
        $referrer->increment('bonus_amount', $bonusAmount);

        try {
            $this->oneCApi->updateBonus(
                $referrer->fullPhone,
                $bonusAmount,
                'add',
                Carbon::now()->format('Y-m-d\TH:i:s'),
                "Бонусы по реферальной программе"
            );
            Log::info("[Referral] Granted {$bonusAmount} bonus to referrer {$referrer->id}");
        } catch (\Exception $e) {
            Log::error("[Referral] Failed to update bonus in 1C for referrer {$referrer->id}: " . $e->getMessage());
        }
    }

    /**
     * Начислить бонусы новому пользователю
     */
    protected function grantBonusToUser(User $user, int $bonusAmount): void
    {
        $user->increment('bonus_amount', $bonusAmount);

        try {
            $this->oneCApi->updateBonus(
                $user->fullPhone,
                $bonusAmount,
                'add',
                Carbon::now()->format('Y-m-d\TH:i:s'),
                "Бонусы за покупку по реферальной программе"
            );
            Log::info("[Referral] Granted {$bonusAmount} bonus to new user {$user->id}");
        } catch (\Exception $e) {
            Log::error("[Referral] Failed to update bonus in 1C for user {$user->id}: " . $e->getMessage());
        }
    }

    /**
     * Выдать подарок рефереру с высокой скидкой
     */
    protected function grantGiftToReferrer(User $referrer, int $promotionId): void
    {
        $promotion = Promotion::with('gifts.giftCatalog')->find($promotionId);

        if (!$promotion || $promotion->gifts->isEmpty()) {
            Log::warning("[Referral] No gifts available for promotion {$promotionId}");
            return;
        }

        // Проверяем, не получил ли уже подарок по этой акции
        $existingGift = Gift::where('user_id', $referrer->id)
            ->where('promotion_id', $promotionId)
            ->exists();

        if ($existingGift) {
            Log::info("[Referral] Referrer {$referrer->id} already has gift from promotion {$promotionId}");
            return;
        }

        // Выбираем случайный подарок
        $randomGift = $promotion->gifts->random();

        if (!$randomGift->giftCatalog) {
            Log::error("[Referral] Gift catalog not found for promotion gift {$randomGift->id}");
            return;
        }

        Gift::create([
            'user_id' => $referrer->id,
            'promotion_id' => $promotionId,
            'gift_catalog_id' => $randomGift->gift_catalog_id,
            'name' => $randomGift->giftCatalog->name,
            'image' => $randomGift->giftCatalog->image,
            'status' => Gift::STATUS_PENDING,
            'is_viewed' => false,
            'is_activated' => false,
        ]);

        Log::info("[Referral] Granted gift '{$randomGift->giftCatalog->name}' to referrer {$referrer->id}");
    }

    /**
     * Получить информацию о реферальной программе для мобильного приложения
     */
    public function getInfoForMobile(User $user): array
    {
        $promotion = $this->getActivePromotion();

        if (!$promotion) {
            return [
                'is_available' => false,
                'message' => 'Реферальная программа временно недоступна'
            ];
        }

        $settings = $this->getSettings();

        // Считаем статистику пользователя как реферера
        $referredUsers = User::where('referrer_id', $user->id)->count();
        $totalBonusEarned = 0; // TODO: можно добавить подсчёт заработанных бонусов

        $promoCode = $user->promoCode?->code ?? null;
        
        return [
            'is_available' => true,
            'promo_code' => $promoCode,
            'share_url' => $promoCode ? url("/r/{$promoCode}") : null,
            
            // Флаг: уже применял ли пользователь промокод друга
            'has_used_promo_code' => (bool) $user->used_promo_code,
            
            // Настройки для отображения
            'referrer_bonus_percent' => $settings['referrer_bonus_percent'],
            'referrer_max_purchases' => $settings['referrer_max_purchases'],
            'referrer_high_discount_threshold' => $settings['referrer_high_discount_threshold'],
            'new_user_discount_percent' => $settings['new_user_discount_percent'],
            'new_user_bonus_percent' => $settings['new_user_bonus_percent'],
            'new_user_bonus_purchases' => $settings['new_user_bonus_purchases'],
            
            // Статистика
            'total_referred' => $referredUsers,
            
            // Описание для пользователя
            'description' => $this->generateDescription($settings),
        ];
    }

    /**
     * Генерация описания для мобильного приложения
     */
    protected function generateDescription(array $settings): string
    {
        $desc = "Поделитесь своим промокодом с друзьями!\n\n";
        $desc .= "🎁 Ваш друг получит:\n";
        $desc .= "• Скидку {$settings['new_user_discount_percent']}% на все покупки\n";
        
        if ($settings['new_user_bonus_percent'] > 0) {
            $desc .= "• {$settings['new_user_bonus_percent']}% бонусов с первых {$settings['new_user_bonus_purchases']} покупок\n";
        }
        
        $desc .= "\n💰 Вы получите:\n";
        $desc .= "• {$settings['referrer_bonus_percent']}% бонусов с первых {$settings['referrer_max_purchases']} покупок друга";
        
        return $desc;
    }
}

