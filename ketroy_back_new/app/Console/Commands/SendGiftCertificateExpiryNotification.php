<?php

namespace App\Console\Commands;

use App\Models\DeviceToken;
use App\Models\GiftCertificate;
use App\Models\User;
use Illuminate\Console\Command;
use Carbon\Carbon;
use App\Services\FirebaseService;
use Illuminate\Support\Facades\Log;

class SendGiftCertificateExpiryNotification extends Command
{
    protected $signature = 'notify:gift-certificate-expiry';

    protected $description = 'Отправить уведомление о завершении срока действия подарочного сертификата';

    public function handle()
    {
        $giftCards = GiftCertificate::whereDate('expiry_date', Carbon::now()->addDays(7)->format('Y-m-d'))->get();
        
        foreach ($giftCards as $giftCard) {
            $user = User::find($giftCard->user_id);
            
            if (!$user) {
                continue;
            }
            
            // Получаем АКТИВНЫЙ токен пользователя
            $activeToken = DeviceToken::getActiveTokenForUser($user->id);
            
            if (!empty($activeToken)) {
                $notifications = $user->notifications()->where('is_read', false)->count();
                $badge = $notifications + 1;
                $title = 'Срок действия сертификата истекает!';
                $body = 'Срок действия подарочного сертификата подходит к концу, Вы можете использовать его в течение 7 дней!';
                $firebase = new FirebaseService();
                $firebase->sendPushNotification($giftCard->id, $badge, 'certificate', $activeToken, $title, $body);
                
                Log::info("[GiftCertificateExpiry] Push отправлен пользователю {$user->id}");
            }
        }
    }
}
