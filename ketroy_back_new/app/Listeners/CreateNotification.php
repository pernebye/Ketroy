<?php

namespace App\Listeners;

use App\Events\NotificationSendedEvent;
use App\Models\DeviceToken;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Support\Facades\Log;

class CreateNotification
{
    /**
     * Create the event listener.
     */
    public function __construct()
    {
        //
    }

    /**
     * Handle the event.
     * 
     * Примечание: $event->userId на самом деле содержит device_token (legacy именование).
     * Ищем пользователя по активному токену в device_tokens, а также по legacy полю.
     */
    public function handle(NotificationSendedEvent $event): void
    {
        $deviceToken = $event->userId; // На самом деле это device_token
        
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
            Log::warning('[CreateNotification] User not found for device token', [
                'device_token_prefix' => substr($deviceToken, 0, 20) . '...',
            ]);
            return;
        }
        
        Notification::create([
            "user_id" => $user->id,
            "title" => $event->title,
            "body" => $event->body,
            "is_read" => $event->isRead,
            "label" => $event->label,
            "source_id" => $event->sourceId,
        ]);
    }
}
