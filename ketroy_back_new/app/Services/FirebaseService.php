<?php

namespace App\Services;

use App\Events\NotificationSendedEvent;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

/**
 * Сервис Firebase Cloud Messaging
 *
 * Отвечает за отправку push-уведомлений на устройства пользователей.
 */
class FirebaseService
{
    protected ?string $projectId;
    protected ?string $accessToken = null;
    protected ?int $tokenExpiresAt = null;

    public function __construct()
    {
        $this->projectId = config('services.fcm.project_id');
    }

    /**
     * Отправить push-уведомление на одно устройство
     */
    public function sendPushNotification(
        ?int $sourceId,
        int $badge,
        string $label,
        string $deviceToken,
        string $title,
        string $body,
        array $data = []
    ): bool {
        if (empty($deviceToken)) {
            Log::warning('FCM: Empty device token provided');
            return false;
        }

        try {
            $accessToken = $this->getAccessToken();

            // КРИТИЧЕСКИ ВАЖНО: Всегда добавляем data payload для работы getInitialMessage()
            // На Android без data payload приложение не получит данные при клике
            $dataPayload = array_merge([
                'type' => $label,
                'label' => $label,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ], $data);
            
            // Добавляем source_id если есть
            if ($sourceId !== null) {
                $dataPayload['source_id'] = (string) $sourceId;
            }

            $message = [
                'token' => $deviceToken,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                ],
                // ОБЯЗАТЕЛЬНО: data payload для навигации при клике
                'data' => array_map('strval', $dataPayload),
                'apns' => [
                    'payload' => [
                        'aps' => [
                            'badge' => $badge,
                            'sound' => 'default',
                            'mutable-content' => 1,
                        ],
                    ],
                ],
                'android' => [
                    'priority' => 'high',
                    'notification' => [
                        'sound' => 'default',
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                        'channel_id' => 'high_importance_channel',
                    ],
                ],
            ];
            
            $payload = ['message' => $message];

            // Отправляем через curl для обхода SSL проблем на Windows
            $caPath = storage_path('app/cacert.pem');
            
            $ch = curl_init("https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send");
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Content-Type: application/json',
                'Authorization: Bearer ' . $accessToken,
            ]);
            curl_setopt($ch, CURLOPT_TIMEOUT, 10);
            
            if (file_exists($caPath)) {
                curl_setopt($ch, CURLOPT_CAINFO, $caPath);
            } else {
                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
            }
            
            $responseBody = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $error = curl_error($ch);
            curl_close($ch);
            
            if ($error) {
                Log::error('FCM: Curl error', ['error' => $error]);
                return false;
            }
            
            $response = json_decode($responseBody, true);

            if ($httpCode >= 200 && $httpCode < 300) {
                event(new NotificationSendedEvent($deviceToken, $title, $body, false, $label, $sourceId));
                return true;
            }

            Log::error('FCM: Failed to send notification', [
                'status' => $httpCode,
                'response' => $response,
                'device_token' => substr($deviceToken, 0, 20) . '...',
            ]);

            return false;
        } catch (\Exception $e) {
            Log::error('FCM: Exception while sending notification', [
                'error' => $e->getMessage(),
                'device_token' => substr($deviceToken, 0, 20) . '...',
            ]);
            return false;
        }
    }

    /**
     * Отправить push-уведомление на несколько устройств
     */
    public function sendMulticastNotification(
        array $tokens,
        string $title,
        string $body,
        array $data = []
    ): array {
        $results = [
            'success' => 0,
            'failure' => 0,
            'errors' => [],
        ];

        // FCM v1 API не поддерживает multicast напрямую,
        // отправляем по одному (можно оптимизировать через batch)
        foreach ($tokens as $token) {
            try {
                $success = $this->sendPushNotification(
                    null,
                    0,
                    'multicast',
                    $token,
                    $title,
                    $body,
                    $data
                );

                if ($success) {
                    $results['success']++;
                } else {
                    $results['failure']++;
                }
            } catch (\Exception $e) {
                $results['failure']++;
                $results['errors'][] = $e->getMessage();
            }
        }

        Log::info('FCM: Multicast completed', $results);

        return $results;
    }

    /**
     * Получить access token для Firebase API
     * Использует raw curl для обхода проблем с SSL на Windows
     */
    protected function getAccessToken(): string
    {
        // Используем кэшированный токен если он ещё действителен
        if ($this->accessToken && $this->tokenExpiresAt && time() < $this->tokenExpiresAt - 60) {
            return $this->accessToken;
        }

        $credentialsPath = Storage::path('json/file.json');

        if (!file_exists($credentialsPath)) {
            throw new \RuntimeException('Firebase credentials file not found');
        }

        $credentials = json_decode(file_get_contents($credentialsPath), true);
        
        // Создаём JWT assertion вручную
        $now = time();
        $header = [
            'alg' => 'RS256',
            'typ' => 'JWT',
        ];
        
        $payload = [
            'iss' => $credentials['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => $credentials['token_uri'],
            'iat' => $now,
            'exp' => $now + 3600,
        ];
        
        $headerEncoded = $this->base64UrlEncode(json_encode($header));
        $payloadEncoded = $this->base64UrlEncode(json_encode($payload));
        
        $dataToSign = $headerEncoded . '.' . $payloadEncoded;
        
        // Подписываем JWT
        $privateKey = openssl_pkey_get_private($credentials['private_key']);
        openssl_sign($dataToSign, $signature, $privateKey, OPENSSL_ALGO_SHA256);
        
        $signatureEncoded = $this->base64UrlEncode($signature);
        $jwt = $dataToSign . '.' . $signatureEncoded;
        
        // Обмениваем JWT на access token через curl
        $caPath = storage_path('app/cacert.pem');
        
        $ch = curl_init($credentials['token_uri']);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]));
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/x-www-form-urlencoded']);
        
        // Настройка SSL
        if (file_exists($caPath)) {
            curl_setopt($ch, CURLOPT_CAINFO, $caPath);
        } else {
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
        }
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);
        
        if ($error) {
            throw new \RuntimeException('Failed to get Firebase access token: ' . $error);
        }
        
        $token = json_decode($response, true);
        
        if (isset($token['error'])) {
            throw new \RuntimeException('Failed to get Firebase access token: ' . ($token['error_description'] ?? $token['error']));
        }

        $this->accessToken = $token['access_token'];
        $this->tokenExpiresAt = time() + ($token['expires_in'] ?? 3600);
        
        Log::info('FCM: Access token obtained successfully');

        return $this->accessToken;
    }
    
    /**
     * Base64 URL encode
     */
    private function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Проверить валидность device token
     */
    public function validateToken(string $deviceToken): bool
    {
        // Базовая валидация формата токена
        if (empty($deviceToken) || strlen($deviceToken) < 100) {
            return false;
        }

        return true;
    }

    /**
     * Отправить тестовое уведомление
     */
    public function sendTestNotification(string $deviceToken): bool
    {
        return $this->sendPushNotification(
            null,
            1,
            'test',
            $deviceToken,
            'Тестовое уведомление',
            'Это тестовое уведомление от Ketroy',
            ['type' => 'test'] // Обязательно передаём data
        );
    }
}
