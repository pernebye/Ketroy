<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class LoyaltyLevelReward extends Model
{
    use HasFactory;

    protected $fillable = [
        'loyalty_level_id',
        'reward_type',
        'discount_percent',
        'bonus_amount',
        'description',
        'is_active',
    ];

    protected $casts = [
        'discount_percent' => 'integer',
        'bonus_amount' => 'integer',
        'is_active' => 'boolean',
    ];

    /**
     * Уровень лояльности
     */
    public function loyaltyLevel(): BelongsTo
    {
        return $this->belongsTo(LoyaltyLevel::class);
    }

    /**
     * Подарки для выбора (если тип reward_type = gift_choice)
     */
    public function giftOptions(): BelongsToMany
    {
        return $this->belongsToMany(GiftCatalog::class, 'loyalty_reward_gifts', 'loyalty_level_reward_id', 'gift_catalog_id');
    }

    /**
     * Получить описание награды для отображения
     */
    public function getRewardDescription(): string
    {
        if ($this->description) {
            return $this->description;
        }

        return match($this->reward_type) {
            'discount' => "Персональная скидка {$this->discount_percent}%",
            'bonus' => "Бонусы: " . number_format($this->bonus_amount, 0, '', ' ') . " ₸",
            'gift_choice' => "Выбор подарка из " . $this->giftOptions()->count() . " вариантов",
            default => 'Награда',
        };
    }
}






