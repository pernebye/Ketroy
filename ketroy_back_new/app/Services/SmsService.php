<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Сервис отправки SMS через Mobizon
 */
class SmsService
{
    protected string $apiKey;
    protected string $apiServer;
    protected bool $isEnabled;

    public function __construct()
    {
        $this->apiKey = config('services.mobizon.api_key', '');
        $this->apiServer = config('services.mobizon.api_server', 'api.mobizon.kz');
        $this->isEnabled = !empty($this->apiKey);
    }

    /**
     * Отправить SMS сообщение
     */
    public function send(string $phone, string $message): bool
    {
        if (!$this->isEnabled) {
            Log::info('SMS Service: Disabled, message not sent', [
                'phone' => $this->maskPhone($phone),
                'message_length' => strlen($message),
            ]);
            return false;
        }

        try {
            $url = "https://{$this->apiServer}/service/message/sendSmsMessage";
            
            // Используем Laravel HTTP Client
            $request = Http::asForm();
            
            // Для локальной разработки отключаем проверку SSL
            if (config('app.env') === 'local') {
                $request = $request->withoutVerifying();
            }
            
            $response = $request->post($url, [
                'apiKey' => $this->apiKey,
                'recipient' => $this->formatPhoneNumber($phone),
                'text' => $message,
            ]);

            $data = $response->json();

            if ($response->successful() && isset($data['code']) && $data['code'] == 0) {
                Log::info('SMS sent successfully', [
                    'phone' => $this->maskPhone($phone),
                    'messageId' => $data['data']['messageId'] ?? null,
                ]);
                return true;
            }

            Log::warning('SMS: Failed to send', [
                'phone' => $this->maskPhone($phone),
                'response' => $data,
            ]);
            return false;
        } catch (\Exception $e) {
            Log::error('SMS: Exception while sending', [
                'phone' => $this->maskPhone($phone),
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    /**
     * Форматировать номер телефона
     */
    protected function formatPhoneNumber(string $phone): string
    {
        return preg_replace('/[^0-9]/', '', $phone);
    }

    /**
     * Маскировать номер телефона для логов
     */
    protected function maskPhone(string $phone): string
    {
        $digits = preg_replace('/[^0-9]/', '', $phone);
        if (strlen($digits) < 4) {
            return '***';
        }
        return substr($digits, 0, 3) . '****' . substr($digits, -2);
    }

    /**
     * Проверить доступность сервиса
     */
    public function isAvailable(): bool
    {
        return $this->isEnabled;
    }

    /**
     * Получить баланс аккаунта
     */
    public function getBalance(): ?float
    {
        if (!$this->isEnabled) {
            return null;
        }

        try {
            $url = "https://{$this->apiServer}/service/user/getOwnBalance";
            
            $request = Http::asForm();
            if (config('app.env') === 'local') {
                $request = $request->withoutVerifying();
            }
            
            $response = $request->post($url, [
                'apiKey' => $this->apiKey,
            ]);

            $data = $response->json();

            if ($response->successful() && isset($data['data']['balance'])) {
                return (float) $data['data']['balance'];
            }

            return null;
        } catch (\Exception $e) {
            Log::error('SMS: Failed to get balance', ['error' => $e->getMessage()]);
            return null;
        }
    }
}
