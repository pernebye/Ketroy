<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AnalyticsEvent extends Model
{
    use HasFactory;

    protected $fillable = [
        'event_type', // Тип события: view, click, promo_code_use и т.д.
        'event_data', // Дополнительные данные (JSON).
        'user_id', // Пользователь, который вызвал событие.
        'created_at', // Время события.
    ];

    protected $casts = [
        'event_data' => 'array',
        'created_at' => 'datetime',
    ];

    /**
     * Связь с моделью User.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
