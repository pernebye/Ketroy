<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PromotionGift extends Model
{
    use HasFactory;

    protected $fillable = ['promotion_id', 'gift_catalog_id'];

    protected $with = ['giftCatalog'];
        
    public function promotion()
    {
        return $this->belongsTo(Promotion::class);
    }

    /**
     * Связь с каталогом подарков
     */
    public function giftCatalog()
    {
        return $this->belongsTo(GiftCatalog::class, 'gift_catalog_id');
    }

    /**
     * Получить название подарка из каталога
     */
    public function getGiftNameAttribute(): ?string
    {
        return $this->giftCatalog?->name;
    }

    /**
     * Получить изображение подарка из каталога
     */
    public function getGiftImageAttribute(): ?string
    {
        return $this->giftCatalog?->image_url;
    }
}
