<?php

namespace App\Services;

use App\Models\Gift;
use App\Models\Promotion;
use App\Models\PromotionGift;
use App\Models\Purchase;
use App\Models\User;

class GiftService
{

    /**
     * Проверяет, достиг ли пользователь порога для получения подарка по акции накопления.
     * Возвращает true если пользователь имеет право выбрать подарок.
     */
    public function checkEligibilityByPurchaseTotal(User $user, Promotion $promotion): bool
    {
        // Получаем порог из settings акции
        $settings = is_array($promotion->settings) ? $promotion->settings : json_decode($promotion->settings, true);
        $minPurchaseAmount = $settings['min_purchase_amount'] ?? 0;

        $totalSpent = Purchase::where('user_id', $user->id)
            ->sum('total_price');

        // Проверяем, достиг ли пользователь порога и не получал ли уже подарок
        return $totalSpent >= $minPurchaseAmount && !$this->alreadyHasGift($user->id, $promotion->id);
    }

    /**
     * Позволяет пользователю выбрать подарок из доступных в акции.
     * @param int $giftId - ID записи в promotion_gifts (не gift_catalog!)
     */
    public function assignSelectedGift(User $user, Promotion $promotion, int $giftId): ?Gift
    {
        // Проверяем право на подарок
        if (!$this->checkEligibilityByPurchaseTotal($user, $promotion)) {
            return null;
        }

        // Проверяем, что выбранный подарок принадлежит этой акции
        $selectedGift = PromotionGift::with('giftCatalog')
            ->where('promotion_id', $promotion->id)
            ->where('id', $giftId)
            ->first();

        if (!$selectedGift || !$selectedGift->giftCatalog) {
            return null;
        }

        return Gift::create([
            'user_id' => $user->id,
            'promotion_id' => $promotion->id,
            'name' => $selectedGift->giftCatalog->name,
            'image' => $selectedGift->giftCatalog->image,
            'is_viewed' => false,
            'is_activated' => false
        ]);
    }

    public function checkAndAssignGiftByDatePromotions(): void
    {
        $today = now()->toDateString();

        $promotions = Promotion::where('type', 'date_based')
            ->whereDate('end_date', $today)
            ->where('is_archived', false)
            ->get();

        foreach ($promotions as $promotion) {
            $giftTier = PromotionGift::with('giftCatalog')
                ->where('promotion_id', $promotion->id)
                ->inRandomOrder()
                ->first();

            if (!$giftTier || !$giftTier->giftCatalog) {
                continue;
            }

            $users = User::all();

            foreach ($users as $user) {
                if (!$this->alreadyHasGift($user->id, $promotion->id)) {
                    Gift::create([
                        'user_id' => $user->id,
                        'promotion_id' => $promotion->id,
                        'name' => $giftTier->giftCatalog->name,
                        'image' => $giftTier->giftCatalog->image,
                        'is_viewed' => false,
                        'is_activated' => false
                    ]);
                }
            }
            $promotion->is_archived = true;
            $promotion->save();
        }
    }



    private function alreadyHasGift(int $userId, int $promotionId): bool
    {
        return Gift::where('user_id', $userId)
            ->where('promotion_id', $promotionId)
            ->exists();
    }
}
