<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class OneCSyncService
{
    protected $baseUrl;

    public function __construct()
    {
        $this->baseUrl = config('services.one_c.base_url');
    }

    /**
     * Получение данных о бонусах и скидках из 1С.
     */
    public function getBonusesAndDiscounts($userId)
    {
        $response = Http::get("{$this->baseUrl}/getBonusesAndDiscounts", [
            'user_id' => $userId,
        ]);

        return $response->json();
    }

    /**
     * Отправка данных о подарочных сертификатах в 1С.
     */
    public function syncGiftCertificate($certificateData)
    {
        $response = Http::post("{$this->baseUrl}/syncGiftCertificate", $certificateData);

        return $response->ok();
    }
}