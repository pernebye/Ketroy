<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Log;

class DeviceToken extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'token',
        'is_active',
        'device_type',
        'device_info',
        'last_used_at',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'last_used_at' => 'datetime',
    ];

    /**
     * Связь с пользователем
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Scope: только активные токены
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope: по токену устройства
     */
    public function scopeByToken($query, string $token)
    {
        return $query->where('token', $token);
    }

    /**
     * Активировать токен для пользователя и деактивировать для остальных
     * 
     * @param int $userId ID пользователя
     * @param string $token FCM токен устройства
     * @param string|null $deviceType Тип устройства (ios, android, web)
     * @param string|null $deviceInfo Дополнительная информация
     * @return self
     */
    public static function activateForUser(
        int $userId, 
        string $token, 
        ?string $deviceType = null,
        ?string $deviceInfo = null
    ): self {
        // 1. Деактивируем этот токен для ВСЕХ остальных пользователей
        self::where('token', $token)
            ->where('user_id', '!=', $userId)
            ->update(['is_active' => false]);

        // 2. Создаём или обновляем запись для текущего пользователя
        $deviceToken = self::updateOrCreate(
            [
                'user_id' => $userId,
                'token' => $token,
            ],
            [
                'is_active' => true,
                'device_type' => $deviceType,
                'device_info' => $deviceInfo,
                'last_used_at' => now(),
            ]
        );

        Log::info('[DeviceToken] Token activated for user', [
            'user_id' => $userId,
            'token_prefix' => substr($token, 0, 20) . '...',
        ]);

        return $deviceToken;
    }

    /**
     * Деактивировать все токены пользователя (при logout)
     * 
     * @param int $userId ID пользователя
     * @param string|null $token Конкретный токен (если null - деактивировать все)
     */
    public static function deactivateForUser(int $userId, ?string $token = null): void
    {
        $query = self::where('user_id', $userId);
        
        if ($token) {
            $query->where('token', $token);
        }
        
        $count = $query->update(['is_active' => false]);

        Log::info('[DeviceToken] Tokens deactivated for user', [
            'user_id' => $userId,
            'count' => $count,
        ]);
    }

    /**
     * Получить активный токен пользователя
     * 
     * @param int $userId ID пользователя
     * @return string|null FCM токен или null
     */
    public static function getActiveTokenForUser(int $userId): ?string
    {
        $deviceToken = self::where('user_id', $userId)
            ->where('is_active', true)
            ->orderByDesc('last_used_at')
            ->first();

        return $deviceToken?->token;
    }

    /**
     * Проверить, активен ли пользователь на каком-либо устройстве
     * 
     * @param int $userId ID пользователя
     * @return bool
     */
    public static function isUserActive(int $userId): bool
    {
        return self::where('user_id', $userId)
            ->where('is_active', true)
            ->exists();
    }

    /**
     * Получить всех активных пользователей с их токенами
     * 
     * @return \Illuminate\Database\Eloquent\Collection
     */
    public static function getAllActiveTokens()
    {
        return self::where('is_active', true)
            ->with('user')
            ->get();
    }

    /**
     * Очистить неактивные токены старше N дней
     * 
     * @param int $days Количество дней
     * @return int Количество удалённых записей
     */
    public static function cleanupOldTokens(int $days = 90): int
    {
        return self::where('is_active', false)
            ->where('updated_at', '<', now()->subDays($days))
            ->delete();
    }
}

