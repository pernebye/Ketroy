<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class LoyaltyLevel extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'icon',
        'color',
        'min_purchase_amount',
        'order',
        'is_active',
    ];

    protected $casts = [
        'min_purchase_amount' => 'integer',
        'order' => 'integer',
        'is_active' => 'boolean',
    ];

    /**
     * Награды за достижение уровня
     */
    public function rewards(): HasMany
    {
        return $this->hasMany(LoyaltyLevelReward::class);
    }

    /**
     * Активные награды
     */
    public function activeRewards(): HasMany
    {
        return $this->hasMany(LoyaltyLevelReward::class)->where('is_active', true);
    }

    /**
     * История получения наград пользователями
     */
    public function userRewards(): HasMany
    {
        return $this->hasMany(UserLoyaltyReward::class);
    }

    /**
     * Получить уровень пользователя по сумме покупок
     */
    public static function getLevelForPurchaseSum(int $purchaseSum): ?self
    {
        return self::where('is_active', true)
            ->where('min_purchase_amount', '<=', $purchaseSum)
            ->orderBy('min_purchase_amount', 'desc')
            ->first();
    }

    /**
     * Получить следующий уровень
     */
    public function getNextLevel(): ?self
    {
        return self::where('is_active', true)
            ->where('min_purchase_amount', '>', $this->min_purchase_amount)
            ->orderBy('min_purchase_amount', 'asc')
            ->first();
    }

    /**
     * Получить все активные уровни отсортированные по порядку
     */
    public static function getActiveLevels()
    {
        return self::where('is_active', true)
            ->orderBy('order')
            ->orderBy('min_purchase_amount')
            ->get();
    }
}






