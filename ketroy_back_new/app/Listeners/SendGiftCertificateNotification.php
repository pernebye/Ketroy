<?php

namespace App\Listeners;

use App\Events\GiftCertificateCreated;
use App\Models\User;
use App\Services\FirebaseService;
use Illuminate\Support\Facades\Log;


class SendGiftCertificateNotification
{
    /**
     * Обработайте событие.
     */
    public function handle(GiftCertificateCreated $event)
    {
        $title = 'Вы получили подарочный сертификат!';
        $body = "На сумму: {$event->amount} тенге";

        // Отправка уведомления
        $firebase = new FirebaseService();
        // $firebase->sendPushNotification(null, 'certificate', $event->deviceToken, $title, $body);
    }
}
