<?php

namespace App\Jobs;

use App\Models\DeviceToken;
use App\Models\Promotion;
use App\Models\User;
use App\Services\FirebaseService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendLotteryPushNotificationsJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct()
    {
        //
    }

    /**
     * Отправляет push-уведомления для активных лотерей по расписанию
     */
    public function handle(FirebaseService $firebaseService): void
    {
        // Получаем лотереи, которые нужно отправить
        $promotions = Promotion::pendingPushNotifications()->get();

        if ($promotions->isEmpty()) {
            Log::info('No lottery push notifications to send');
            return;
        }

        foreach ($promotions as $promotion) {
            $this->sendNotificationsForPromotion($promotion, $firebaseService);
        }
    }

    protected function sendNotificationsForPromotion(Promotion $promotion, FirebaseService $firebaseService): void
    {
        $title = $promotion->push_title ?? 'У вас подарок! 🎁';
        $body = $promotion->push_text ?? 'Зайдите в приложение, чтобы получить свой подарок!';

        // Получаем всех пользователей с АКТИВНЫМ device_token (авторизованных на устройстве)
        $users = User::whereHas('deviceTokens', function ($query) {
            $query->where('is_active', true);
        })->get();

        $successCount = 0;
        $failureCount = 0;

        foreach ($users as $user) {
            try {
                // Получаем активный токен
                $activeToken = DeviceToken::getActiveTokenForUser($user->id);
                
                if (empty($activeToken)) {
                    continue;
                }
                
                $success = $firebaseService->sendPushNotification(
                    $promotion->id,
                    1, // badge
                    'lottery',
                    $activeToken, // Используем активный токен
                    $title,
                    $body,
                    [
                        'type' => 'lottery',
                        'promotion_id' => (string) $promotion->id,
                    ]
                );

                if ($success) {
                    $successCount++;
                } else {
                    $failureCount++;
                }
            } catch (\Exception $e) {
                $failureCount++;
                Log::error('Failed to send lottery push notification', [
                    'user_id' => $user->id,
                    'promotion_id' => $promotion->id,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        // Отмечаем, что уведомления отправлены
        $promotion->update(['push_sent' => true]);

        Log::info('Lottery push notifications sent', [
            'promotion_id' => $promotion->id,
            'success_count' => $successCount,
            'failure_count' => $failureCount,
        ]);
    }
}

