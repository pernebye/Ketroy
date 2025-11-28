<?php

namespace App\Listeners;

use App\Events\BonusUpdated;
use App\Models\DeviceToken;
use App\Models\User;
use App\Services\FirebaseService;
use Illuminate\Support\Facades\Log;

class SendBonusNotification
{
    /**
     * Примечание: $event->device_token на самом деле содержит device_token устройства.
     * Ищем пользователя по активному токену в device_tokens.
     */
    public function handle(BonusUpdated $event)
    {
        $deviceToken = $event->device_token;
        
        // Сначала ищем в новой таблице device_tokens (активный токен)
        $deviceTokenRecord = DeviceToken::where('token', $deviceToken)
            ->where('is_active', true)
            ->first();
        
        $user = null;
        
        if ($deviceTokenRecord) {
            $user = $deviceTokenRecord->user;
        } else {
            // Fallback: ищем по legacy полю device_token в users
            $user = User::where('device_token', $deviceToken)->first();
        }
        
        if (!$user) {
            Log::warning('[BonusNotification] User not found for device token');
            return;
        }
        
        // Получаем АКТИВНЫЙ токен пользователя (может быть другой, если переавторизовался)
        $activeToken = DeviceToken::getActiveTokenForUser($user->id);
        
        if (!empty($activeToken)) {
            $notifications = $user->notifications()->where('is_read', false)->count();
            $badge = $notifications + 1;
            $body = "Вам начислено {$event->amount} баллов. Спасибо за использование нашего приложения!";
            $title = "Покупка";
            $firebase = new FirebaseService();
            $firebase->sendPushNotification(null, $badge, 'bonus', $activeToken, $title, $body);
            
            Log::info("[BonusNotification] Push sent to user {$user->id}");
        }
    }
}
