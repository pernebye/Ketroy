<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserLotteryParticipation extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'promotion_id',
        'modal_shown',
        'modal_shown_at',
        'gift_claimed',
        'gift_claimed_at',
    ];

    protected $casts = [
        'modal_shown' => 'boolean',
        'modal_shown_at' => 'datetime',
        'gift_claimed' => 'boolean',
        'gift_claimed_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function promotion()
    {
        return $this->belongsTo(Promotion::class);
    }
}

