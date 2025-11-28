<?php

namespace App\Observers;

use App\Models\DeviceToken;
use App\Models\Gift;
use App\Models\User;
use App\Services\FirebaseService;
use Illuminate\Support\Facades\Log;


class GiftObserver
{
    /**
     * Handle the Gift "created" event.
     */
    public function created(Gift $gift): void
    {
        $firebase = new FirebaseService();
        $title = 'Вы получили подарок!';
        $body = 'Активируйте или сохраните его!';

        $user = User::find($gift->user_id);
        
        if (!$user) {
            return;
        }
        
        // Получаем АКТИВНЫЙ токен пользователя
        $activeToken = DeviceToken::getActiveTokenForUser($user->id);
        
        if (!empty($activeToken)) {
            $notifications = $user->notifications()->where('is_read', false)->count();
            $badge = $notifications + 1;

            $firebase->sendPushNotification($gift->id, $badge, 'gift', $activeToken, $title, $body);
            
            Log::info('[GiftObserver] Push sent for gift', [
                'gift_id' => $gift->id,
                'user_id' => $user->id,
            ]);
        }
    }

    /**
     * Handle the Gift "updated" event.
     */
    public function updated(Gift $gift): void
    {
        //
    }

    /**
     * Handle the Gift "deleted" event.
     */
    public function deleted(Gift $gift): void
    {
        //
    }

    /**
     * Handle the Gift "restored" event.
     */
    public function restored(Gift $gift): void
    {
        //
    }

    /**
     * Handle the Gift "force deleted" event.
     */
    public function forceDeleted(Gift $gift): void
    {
        //
    }
}
