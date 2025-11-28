<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;


class User extends Authenticatable
{
    use HasApiTokens, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'surname',
        'device_token', // Deprecated: используйте deviceTokens() связь
        'avatar_image',
        'phone',
        'country_code',
        'city',
        'birthdate',
        'height',
        'clothing_size',
        'shoe_size',
        'one_c_id',
        'bonus_amount',
        'used_promo_code',
        'discount',
        'referrer_id',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */

    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }

    public function purchases()
    {
        return $this->hasMany(Purchase::class);
    }

    public function giftCertificates()
    {
        return $this->hasMany(GiftCertificate::class);
    }

    public function gifts()
    {
        return $this->hasMany(Gift::class);
    }

    public function promoCode()
    {
        return $this->hasOne(PromoCode::class);
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    /**
     * Все device токены пользователя
     */
    public function deviceTokens()
    {
        return $this->hasMany(DeviceToken::class);
    }

    /**
     * Активные device токены (где пользователь авторизован)
     */
    public function activeDeviceTokens()
    {
        return $this->hasMany(DeviceToken::class)->where('is_active', true);
    }

    /**
     * Получить активный FCM токен пользователя
     * Возвращает токен только если пользователь авторизован на устройстве
     * 
     * @return string|null
     */
    public function getActiveDeviceToken(): ?string
    {
        return DeviceToken::getActiveTokenForUser($this->id);
    }

    /**
     * Проверить, авторизован ли пользователь на каком-либо устройстве
     * 
     * @return bool
     */
    public function hasActiveDevice(): bool
    {
        return DeviceToken::isUserActive($this->id);
    }

    /**
     * Награды за уровни лояльности
     */
    public function loyaltyRewards()
    {
        return $this->hasMany(UserLoyaltyReward::class);
    }

    /**
     * Текущий (максимальный) уровень лояльности
     */
    public function currentLoyaltyLevel()
    {
        $reward = $this->loyaltyRewards()
            ->with('loyaltyLevel')
            ->whereHas('loyaltyLevel', function ($q) {
                $q->where('is_active', true);
            })
            ->orderByDesc('achieved_at')
            ->first();

        return $reward?->loyaltyLevel;
    }

    /**
     * Полный номер телефона для 1С (формат 87771234567)
     */
    public function getFullPhoneAttribute(): string
    {
        return str_replace('+7', '8', $this->country_code) . $this->phone;
    }
}
