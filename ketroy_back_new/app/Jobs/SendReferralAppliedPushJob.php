<?php

namespace App\Jobs;

use App\Models\DeviceToken;
use App\Models\Notification;
use App\Models\User;
use App\Services\FirebaseService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Отправка push-уведомления рефереру о том, что его промокод применён
 */
class SendReferralAppliedPushJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected int $referrerId;
    protected int $newUserId;

    /**
     * Create a new job instance.
     */
    public function __construct(int $referrerId, int $newUserId)
    {
        $this->referrerId = $referrerId;
        $this->newUserId = $newUserId;
    }

    /**
     * Execute the job.
     */
    public function handle(FirebaseService $firebaseService): void
    {
        $referrer = User::find($this->referrerId);
        $newUser = User::find($this->newUserId);

        if (!$referrer || !$newUser) {
            Log::warning('[Referral Push] User not found', [
                'referrer_id' => $this->referrerId,
                'new_user_id' => $this->newUserId,
            ]);
            return;
        }

        // Формируем имя друга
        $friendName = trim(($newUser->name ?? '') . ' ' . ($newUser->surname ?? ''));
        if (empty($friendName)) {
            $friendName = 'Новый пользователь';
        }

        $title = 'Ваш промокод применён! 🎉';
        $body = "{$friendName} использовал(а) ваш промокод. Теперь вы будете получать бонусы с покупок друга!";

        // Создаём запись уведомления в БД
        $notification = Notification::create([
            'user_id' => $referrer->id,
            'title' => $title,
            'body' => $body,
            'is_read' => false,
            'label' => 'discount', // Тип "Скидки"
            'source_id' => null,
        ]);

        // Получаем АКТИВНЫЙ токен реферера
        $activeToken = DeviceToken::getActiveTokenForUser($referrer->id);
        
        // Отправляем push-уведомление если пользователь авторизован на устройстве
        if (!empty($activeToken)) {
            $unreadCount = Notification::where('user_id', $referrer->id)
                ->where('is_read', false)
                ->count();

            $firebaseService->sendPushNotification(
                $notification->id,
                $unreadCount,
                'discount', // label для типа уведомления
                $activeToken, // Используем активный токен
                $title,
                $body,
                [
                    'type' => 'referral_applied',
                    'new_user_id' => (string) $newUser->id,
                    'notification_id' => (string) $notification->id,
                ]
            );

            Log::info('[Referral Push] Notification sent to referrer', [
                'referrer_id' => $referrer->id,
                'new_user_name' => $friendName,
            ]);
        } else {
            Log::info('[Referral Push] Notification created (no active device token)', [
                'referrer_id' => $referrer->id,
                'new_user_name' => $friendName,
            ]);
        }
    }
}

