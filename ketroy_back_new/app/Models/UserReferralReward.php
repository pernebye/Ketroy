<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserReferralReward extends Model
{
    protected $fillable = [
        'user_id',
        'referrer_id',
        'promotion_id',
        'settings_snapshot',
        'applied_at',
        'purchases_rewarded',
    ];

    protected $casts = [
        'settings_snapshot' => 'array',
        'applied_at' => 'datetime',
        'purchases_rewarded' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function referrer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'referrer_id');
    }

    public function promotion(): BelongsTo
    {
        return $this->belongsTo(Promotion::class);
    }
}




