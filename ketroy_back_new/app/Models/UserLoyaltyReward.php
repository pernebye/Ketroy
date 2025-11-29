<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserLoyaltyReward extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'loyalty_level_id',
        'loyalty_level_reward_id',
        'selected_gift_id',
        'achieved_at',
        'reward_claimed_at',
    ];

    protected $casts = [
        'achieved_at' => 'datetime',
        'reward_claimed_at' => 'datetime',
    ];

    /**
     * Пользователь
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Уровень лояльности
     */
    public function loyaltyLevel(): BelongsTo
    {
        return $this->belongsTo(LoyaltyLevel::class);
    }

    /**
     * Награда
     */
    public function reward(): BelongsTo
    {
        return $this->belongsTo(LoyaltyLevelReward::class, 'loyalty_level_reward_id');
    }

    /**
     * Выбранный подарок
     */
    public function selectedGift(): BelongsTo
    {
        return $this->belongsTo(GiftCatalog::class, 'selected_gift_id');
    }
}





