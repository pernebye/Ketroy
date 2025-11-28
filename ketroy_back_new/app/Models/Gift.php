<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Gift extends Model
{
    // Статусы подарка
    const STATUS_PENDING = 'pending';       // Ожидает выбора пользователем (в группе)
    const STATUS_SELECTED = 'selected';     // Выбран пользователем
    const STATUS_ACTIVATED = 'activated';   // Активирован в магазине (после QR-скана)
    const STATUS_ISSUED = 'issued';         // Выдан пользователю

    protected $fillable = [
        'user_id', 
        'name',
        'description',
        'is_viewed', 
        'image', 
        'is_activated', 
        'promotion_id',
        'status',
        'gift_group_id',
        'gift_catalog_id',
        'selected_at',
        'issued_at',
        'issuance_qr_code'
    ];

    protected $casts = [
        'is_viewed' => 'boolean',
        'is_activated' => 'boolean',
        'selected_at' => 'datetime',
        'issued_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function giftCatalog()
    {
        return $this->belongsTo(GiftCatalog::class);
    }

    public function promotion()
    {
        return $this->belongsTo(Promotion::class);
    }

    /**
     * Получить все подарки в той же группе
     */
    public function groupGifts()
    {
        return $this->hasMany(Gift::class, 'gift_group_id', 'gift_group_id')
            ->where('id', '!=', $this->id);
    }

    /**
     * Проверить, можно ли выбрать подарок
     */
    public function canBeSelected(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }

    /**
     * Проверить, можно ли активировать подарок
     */
    public function canBeActivated(): bool
    {
        return $this->status === self::STATUS_SELECTED;
    }

    /**
     * Проверить, можно ли выдать подарок
     */
    public function canBeIssued(): bool
    {
        return $this->status === self::STATUS_ACTIVATED;
    }

    /**
     * Scope для подарков, ожидающих выбора
     */
    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    /**
     * Scope для выбранных подарков
     */
    public function scopeSelected($query)
    {
        return $query->where('status', self::STATUS_SELECTED);
    }

    /**
     * Scope для активированных подарков
     */
    public function scopeActivated($query)
    {
        return $query->where('status', self::STATUS_ACTIVATED);
    }

    /**
     * Scope для выданных подарков
     */
    public function scopeIssued($query)
    {
        return $query->where('status', self::STATUS_ISSUED);
    }
}
