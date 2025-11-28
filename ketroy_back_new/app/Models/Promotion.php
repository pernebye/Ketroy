<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Promotion extends Model
{
    use HasFactory;

    protected $fillable = [
        'name', 
        'type', 
        'settings', 
        'start_date', 
        'end_date', 
        'is_archived', 
        'is_active', 
        'description',
        // Лотерея - Push-уведомления
        'push_title',
        'push_text',
        'push_send_at',
        'push_sent',
        // Лотерея - Модальное окно
        'modal_title',
        'modal_text',
        'modal_image',
        'modal_button_text',
    ];

    protected $casts = [
        'settings' => 'array',
        'push_send_at' => 'datetime',
        'push_sent' => 'boolean',
    ];

    public function gifts()
    {
        return $this->hasMany(PromotionGift::class);
    }

    public function participations()
    {
        return $this->hasMany(UserLotteryParticipation::class);
    }

    /**
     * Проверить, активна ли акция лотереи сейчас
     */
    public function isLotteryActive(): bool
    {
        if ($this->type !== 'date_based' || $this->is_archived || !$this->is_active) {
            return false;
        }

        $now = now()->toDateString();
        $startDate = $this->start_date;
        $endDate = $this->end_date;

        if ($startDate && $now < $startDate) {
            return false;
        }

        if ($endDate && $now > $endDate) {
            return false;
        }

        return true;
    }

    /**
     * Scope для активных лотерей
     */
    public function scopeActiveLotteries($query)
    {
        $now = now()->toDateString();
        
        return $query->where('type', 'date_based')
            ->where('is_archived', false)
            ->where('is_active', true)
            ->where(function ($q) use ($now) {
                $q->whereNull('start_date')
                    ->orWhere('start_date', '<=', $now);
            })
            ->where(function ($q) use ($now) {
                $q->whereNull('end_date')
                    ->orWhere('end_date', '>=', $now);
            });
    }

    /**
     * Scope для лотерей, требующих отправки push-уведомлений
     */
    public function scopePendingPushNotifications($query)
    {
        return $query->where('type', 'date_based')
            ->where('is_archived', false)
            ->where('is_active', true)
            ->where('push_sent', false)
            ->whereNotNull('push_send_at')
            ->where('push_send_at', '<=', now());
    }
}
