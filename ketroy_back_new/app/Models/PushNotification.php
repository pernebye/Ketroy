<?php

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PushNotification extends Model
{
    use HasFactory;

    // Статусы уведомлений
    const STATUS_DRAFT = 'draft';
    const STATUS_SCHEDULED = 'scheduled';
    const STATUS_SENDING = 'sending';
    const STATUS_SENT = 'sent';
    const STATUS_FAILED = 'failed';
    const STATUS_CANCELLED = 'cancelled';

    protected $fillable = [
        'title',
        'body',
        'status',
        'scheduled_at',
        'sent_at',
        'target_cities',
        'target_clothing_sizes',
        'target_shoe_sizes',
        'recipients_count',
        'sent_count',
        'failed_count',
        'created_by',
        'error_message',
    ];

    protected $casts = [
        'target_cities' => 'array',
        'target_clothing_sizes' => 'array',
        'target_shoe_sizes' => 'array',
        'scheduled_at' => 'datetime',
        'sent_at' => 'datetime',
    ];

    /**
     * Админ, создавший уведомление
     */
    public function creator()
    {
        return $this->belongsTo(Admin::class, 'created_by');
    }

    /**
     * Можно ли редактировать уведомление
     */
    public function isEditable(): bool
    {
        return in_array($this->status, [
            self::STATUS_DRAFT,
            self::STATUS_SCHEDULED,
        ]);
    }

    /**
     * Проверить, готово ли уведомление к отправке
     */
    public function isReadyToSend(): bool
    {
        if ($this->status !== self::STATUS_SCHEDULED) {
            return false;
        }

        if ($this->scheduled_at === null) {
            return true; // Отправить сразу
        }

        return Carbon::now()->gte($this->scheduled_at);
    }

    /**
     * Получить пользователей по таргетингу
     * Возвращает только пользователей с АКТИВНЫМ device token (авторизованных на устройстве)
     */
    public function getTargetUsers()
    {
        // Фильтруем только пользователей с активным device token
        $query = User::query()->whereHas('deviceTokens', function ($q) {
            $q->where('is_active', true);
        });

        // Фильтр по городам
        if (!empty($this->target_cities)) {
            $query->whereIn('city', $this->target_cities);
        }

        // Фильтр по размерам одежды
        if (!empty($this->target_clothing_sizes)) {
            $query->whereIn('clothing_size', $this->target_clothing_sizes);
        }

        // Фильтр по размерам обуви
        if (!empty($this->target_shoe_sizes)) {
            $query->whereIn('shoe_size', $this->target_shoe_sizes);
        }

        return $query;
    }

    /**
     * Подсчитать количество получателей
     */
    public function countRecipients(): int
    {
        return $this->getTargetUsers()->count();
    }

    /**
     * Форматирование дат для JSON
     */
    public function getCreatedAtAttribute($value)
    {
        return Carbon::parse($value)
            ->setTimezone('Asia/Almaty')
            ->toDateTimeString();
    }

    public function getUpdatedAtAttribute($value)
    {
        return Carbon::parse($value)
            ->setTimezone('Asia/Almaty')
            ->toDateTimeString();
    }

    public function getScheduledAtFormattedAttribute()
    {
        if (!$this->scheduled_at) {
            return null;
        }
        return Carbon::parse($this->scheduled_at)
            ->setTimezone('Asia/Almaty')
            ->toDateTimeString();
    }

    public function getSentAtFormattedAttribute()
    {
        if (!$this->sent_at) {
            return null;
        }
        return Carbon::parse($this->sent_at)
            ->setTimezone('Asia/Almaty')
            ->toDateTimeString();
    }

    /**
     * Получить краткую информацию о таргетинге
     */
    public function getTargetingSummaryAttribute(): string
    {
        $parts = [];

        if (!empty($this->target_cities)) {
            $parts[] = 'Города: ' . implode(', ', $this->target_cities);
        }

        if (!empty($this->target_clothing_sizes)) {
            $parts[] = 'Одежда: ' . implode(', ', $this->target_clothing_sizes);
        }

        if (!empty($this->target_shoe_sizes)) {
            $parts[] = 'Обувь: ' . implode(', ', $this->target_shoe_sizes);
        }

        return empty($parts) ? 'Все пользователи' : implode(' | ', $parts);
    }

    /**
     * Scopes
     */
    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_SCHEDULED)
            ->where(function ($q) {
                $q->whereNull('scheduled_at')
                    ->orWhere('scheduled_at', '<=', Carbon::now());
            });
    }

    public function scopeActive($query)
    {
        return $query->whereIn('status', [
            self::STATUS_DRAFT,
            self::STATUS_SCHEDULED,
        ]);
    }
}

