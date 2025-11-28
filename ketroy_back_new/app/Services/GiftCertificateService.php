<?php

namespace App\Services;

use App\Models\GiftCertificate;
use App\Models\User;
use Illuminate\Support\Str;
use Carbon\Carbon;

class GiftCertificateService
{
    public function createCertificate(User $sender, User $recipient, $nominal, $congratulationMessage, $recipientPhone)
    {
        // Генерация уникального штрих-кода
        $barcode = Str::uuid()->toString();

        // Установка срока действия сертификата (6 месяцев с момента покупки)
        $expirationDate = Carbon::now()->addMonths(6);

        // Создание подарочного сертификата
        $giftCertificate = GiftCertificate::create([
            'sender_id' => $sender->id,
            'user_id' => $recipient->id,
            'recipient_phone' => $recipientPhone,
            'congratulation_message' => $congratulationMessage,
            'nominal' => $nominal,
            'barcode' => $barcode,
            'expiration_date' => $expirationDate,
        ]);

        return $giftCertificate;
    }
}
