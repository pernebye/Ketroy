<?php

namespace App\Services;

use App\Models\Gift;
use App\Models\Promotion;
use App\Models\PromotionGift;
use App\Models\User;
use App\Models\UserLotteryParticipation;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class LotteryService
{
    /**
     * Получить активную лотерею для пользователя
     * Возвращает null если нет активной лотереи или пользователь уже участвовал
     */
    public function getActiveLotteryForUser(User $user): ?array
    {
        $activeLottery = Promotion::activeLotteries()
            ->with('gifts.giftCatalog')
            ->first();

        if (!$activeLottery) {
            return null;
        }

        // Проверяем, показывали ли уже модальное окно пользователю
        $participation = UserLotteryParticipation::where('user_id', $user->id)
            ->where('promotion_id', $activeLottery->id)
            ->first();

        if ($participation && $participation->modal_shown) {
            return null;
        }

        // Подготавливаем список подарков
        $gifts = $activeLottery->gifts->map(function ($promotionGift) {
            return [
                'id' => $promotionGift->id,
                'name' => $promotionGift->giftCatalog->name ?? 'Подарок',
                'image' => $promotionGift->giftCatalog->image_url ?? null,
            ];
        })->toArray();

        return [
            'promotion_id' => $activeLottery->id,
            'modal_title' => $activeLottery->modal_title ?? 'Поздравляем! 🎉',
            'modal_text' => $activeLottery->modal_text ?? 'Вы получили подарок!',
            'modal_image' => $activeLottery->modal_image ? url('storage/' . $activeLottery->modal_image) : null,
            'modal_button_text' => $activeLottery->modal_button_text ?? 'Получить подарок',
            'gifts_count' => count($gifts),
            'gifts' => $gifts,
        ];
    }

    /**
     * Отметить показ модального окна и выдать подарок
     */
    public function claimLotteryGift(User $user, int $promotionId): array
    {
        $promotion = Promotion::with('gifts.giftCatalog')
            ->where('type', 'date_based')
            ->where('is_archived', false)
            ->where('is_active', true)
            ->find($promotionId);

        if (!$promotion) {
            return [
                'success' => false,
                'message' => 'Акция не найдена или неактивна',
            ];
        }

        if (!$promotion->isLotteryActive()) {
            return [
                'success' => false,
                'message' => 'Акция уже завершена',
            ];
        }

        // Проверяем, не получал ли уже пользователь подарок
        $participation = UserLotteryParticipation::firstOrCreate(
            [
                'user_id' => $user->id,
                'promotion_id' => $promotionId,
            ],
            [
                'modal_shown' => true,
                'modal_shown_at' => now(),
            ]
        );

        if ($participation->gift_claimed) {
            return [
                'success' => false,
                'message' => 'Вы уже получили подарок в рамках этой акции',
                'gift_already_claimed' => true,
            ];
        }

        // Выбираем случайный подарок из группы
        $promotionGifts = $promotion->gifts;
        
        if ($promotionGifts->isEmpty()) {
            return [
                'success' => false,
                'message' => 'К сожалению, подарки закончились',
            ];
        }

        $randomGift = $promotionGifts->random();
        $giftCatalog = $randomGift->giftCatalog;

        if (!$giftCatalog) {
            return [
                'success' => false,
                'message' => 'Ошибка при получении подарка',
            ];
        }

        // Создаём группу подарков для пользователя
        $giftGroupId = Str::uuid()->toString();

        // Создаём подарки в статусе pending для выбора
        $gifts = [];
        foreach ($promotionGifts as $pGift) {
            if ($pGift->giftCatalog) {
                $gift = Gift::create([
                    'user_id' => $user->id,
                    'promotion_id' => $promotionId,
                    'name' => $pGift->giftCatalog->name,
                    'image' => $pGift->giftCatalog->image,
                    'gift_catalog_id' => $pGift->giftCatalog->id,
                    'gift_group_id' => $giftGroupId,
                    'status' => Gift::STATUS_PENDING,
                    'is_viewed' => false,
                    'is_activated' => false,
                ]);
                $gifts[] = [
                    'id' => $gift->id,
                    'name' => $gift->name,
                    'image' => $gift->giftCatalog?->image_url ?? null,
                ];
            }
        }

        // Обновляем participation
        $participation->update([
            'modal_shown' => true,
            'modal_shown_at' => now(),
            'gift_claimed' => true,
            'gift_claimed_at' => now(),
        ]);

        Log::info('Lottery gift claimed', [
            'user_id' => $user->id,
            'promotion_id' => $promotionId,
            'gift_group_id' => $giftGroupId,
            'gifts_count' => count($gifts),
        ]);

        return [
            'success' => true,
            'message' => 'Подарок успешно получен!',
            'gift_group_id' => $giftGroupId,
            'gifts' => $gifts,
        ];
    }

    /**
     * Отметить показ модального окна без получения подарка
     */
    public function markModalShown(User $user, int $promotionId): void
    {
        UserLotteryParticipation::updateOrCreate(
            [
                'user_id' => $user->id,
                'promotion_id' => $promotionId,
            ],
            [
                'modal_shown' => true,
                'modal_shown_at' => now(),
            ]
        );
    }
}

