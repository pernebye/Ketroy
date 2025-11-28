<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Сервис интеграции с 1С ERP
 *
 * Отвечает за синхронизацию данных клиентов, бонусов и покупок с 1С.
 */
class OneCApiService
{
    protected string $baseUrl;
    protected string $username;
    protected string $password;
    protected int $timeout;
    protected int $retryTimes;
    protected int $retrySleep;

    public function __construct()
    {
        $this->baseUrl = config('services.one_c.base_url');
        $this->username = config('services.one_c.username');
        $this->password = config('services.one_c.password');
        $this->timeout = config('services.one_c.timeout', 30);
        $this->retryTimes = config('services.one_c.retry_times', 3);
        $this->retrySleep = config('services.one_c.retry_sleep', 1000);
    }

    /**
     * Создать HTTP клиент с базовыми настройками
     */
    protected function makeRequest()
    {
        return Http::withBasicAuth($this->username, $this->password)
            ->timeout($this->timeout)
            ->withOptions([
                'connect_timeout' => 5,
                'verify' => false, // Отключаем SSL верификацию
            ]);
    }

    /**
     * Найти или создать клиента в 1С
     */
    public function findOrCreateClient(array $data): ?array
    {
        // Сначала пробуем найти клиента
        $clientInfo = $this->getClientInfo($data['phone']);

        if ($clientInfo) {
            return $clientInfo;
        }

        // Клиент не найден - создаём нового
        return $this->createClient($data);
    }

    /**
     * Получить информацию о клиенте из 1С
     */
    public function getClientInfo(string $phoneNumber): ?array
    {
        try {
            $response = $this->makeRequest()
                ->get("{$this->baseUrl}/user-data", ['phone' => $phoneNumber]);

        if ($response->failed()) {
                $this->handleClientNotFound($phoneNumber);
                return null;
        }

        if ($response->successful() && $response->json()) {
                $this->syncUserBonuses($phoneNumber, $response->json());
                return $response->json();
            }

            return null;
        } catch (\Exception $e) {
            Log::error('1C API Error (getClientInfo)', [
                'phone' => $phoneNumber,
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Создать клиента в 1С
     */
    protected function createClient(array $data): ?array
    {
        try {
            $response = $this->makeRequest()
            ->post("{$this->baseUrl}/create-user", $data);

            if ($response->failed()) {
                Log::error('1C API Error (createClient)', [
                    'phone' => $data['phone'] ?? 'unknown',
                    'response' => $response->body(),
                ]);
                return null;
        }

            return $response->json();
        } catch (\Exception $e) {
            Log::error('1C API Error (createClient)', [
                'data' => $data,
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Обработка случая когда клиент не найден в 1С
     */
    protected function handleClientNotFound(string $phoneNumber): void
    {
        $user = User::where('phone', mb_substr($phoneNumber, 1))->first();

        if (!$user) {
            return;
        }

        // Пробуем создать клиента в 1С
                $data = [
            'fio' => trim($user->surname . ' ' . $user->name),
                    'phone' => str_replace('+7', '8', $user->country_code) . $user->phone,
                    'birthDate' => date("Y-m-d", strtotime($user->birthdate)) . 'T00:00:00'
                ];

        $this->createClient($data);
    }

    /**
     * Синхронизировать бонусы пользователя из 1С
     */
    protected function syncUserBonuses(string $phoneNumber, array $oneCData): void
    {
        $user = User::where('phone', mb_substr($phoneNumber, 1))->first();

        if (!$user) {
            return;
        }

        $user->update([
            'bonus_amount' => $oneCData['bonusAmount'] ?? $user->bonus_amount,
            'discount' => $oneCData['personalDiscount'] ?? $user->discount,
        ]);
    }

    /**
     * Обновить персональную скидку клиента
     */
    public function updateDiscount(string $phone, int $discount): ?array
    {
        try {
            $response = $this->makeRequest()
                ->post("{$this->baseUrl}/update-discount", [
                    'phone' => $phone,
                    'personalDiscount' => $discount,
                ]);

            if ($response->failed()) {
                Log::error('1C API Error (updateDiscount)', [
                    'phone' => $phone,
                    'response' => $response->body(),
                ]);
                return null;
            }

            return $response->json();
        } catch (\Exception $e) {
            Log::error('1C API Error (updateDiscount)', [
                'phone' => $phone,
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Обновить бонусы клиента
     */
    public function updateBonus(
        string $phone,
        int $bonus,
        string $operation,
        string $docDate,
        ?string $comment = null,
        bool $withDelay = true
    ): ?array {
        $startTime = microtime(true);
        
        Log::info('[updateBonus] Starting request to 1C', [
            'phone' => $phone,
            'bonus' => $bonus,
            'operation' => $operation,
            'url' => "{$this->baseUrl}/change-bonuses",
        ]);
        
        try {
            $response = $this->makeRequest()
            ->post("{$this->baseUrl}/change-bonuses", [
                'phone' => $phone,
                'bonusSum' => $bonus,
                'docDate' => $docDate,
                'operation' => $operation,
                'comment' => $comment,
                'withDelay' => $withDelay,
            ]);

            $duration = round((microtime(true) - $startTime) * 1000);
            
            Log::info('[updateBonus] Response received', [
                'phone' => $phone,
                'duration_ms' => $duration,
                'status' => $response->status(),
            ]);

            if ($response->failed()) {
                Log::error('1C API Error (updateBonus)', [
                    'phone' => $phone,
                    'response' => $response->body(),
                    'duration_ms' => $duration,
                ]);
                return null;
            }

            return $response->json();
        } catch (\Exception $e) {
            $duration = round((microtime(true) - $startTime) * 1000);
            Log::error('1C API Error (updateBonus)', [
                'phone' => $phone,
                'error' => $e->getMessage(),
                'duration_ms' => $duration,
            ]);
            return null;
        }
    }

    /**
     * Сгенерировать промокод в 1С
     */
    public function generatePromoCode(array $data): ?string
    {
        try {
            $response = $this->makeRequest()
            ->post("{$this->baseUrl}/promo-codes", $data);

        if ($response->failed()) {
                Log::error('1C API Error (generatePromoCode)', [
                    'data' => $data,
                    'response' => $response->body(),
                ]);
            throw new \Exception('Ошибка при генерации промокода в 1С');
        }

        return $response->json('data');
        } catch (\Exception $e) {
            Log::error('1C API Error (generatePromoCode)', [
                'data' => $data,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }

    /**
     * Получить историю покупок клиента
     */
    public function getClientPurchases(string $phoneNumber): ?array
    {
        try {
            $response = $this->makeRequest()
            ->get("{$this->baseUrl}/purchase-info", ['phone' => $phoneNumber]);

        if ($response->failed()) {
                if ($response->body() === 'Данные не найдены') {
                return null;
                }

                Log::error('1C API Error (getClientPurchases)', [
                    'phone' => $phoneNumber,
                    'response' => $response->body(),
                ]);
                return null;
        }

            return $response->json();
        } catch (\Exception $e) {
            Log::error('1C API Error (getClientPurchases)', [
                'phone' => $phoneNumber,
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Проверить доступность 1С API
     */
    public function healthCheck(): bool
    {
        try {
            $response = $this->makeRequest()
                ->timeout(5)
                ->get("{$this->baseUrl}/health");

            return $response->successful();
        } catch (\Exception $e) {
            return false;
        }
    }
}
