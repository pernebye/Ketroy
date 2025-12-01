<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class GiftCatalog extends Model
{
    use HasFactory;

    protected $table = 'gift_catalog';

    protected $fillable = ['name', 'image', 'description', 'is_active'];

    protected $appends = ['image_url'];

    /**
     * Получить URL изображения
     */
    public function getImageUrlAttribute(): ?string
    {
        if (!$this->image) {
            return null;
        }

        // Если это уже полный URL
        if (str_starts_with($this->image, 'http')) {
            return $this->image;
        }

        // Возвращаем URL из S3
        return Storage::disk('s3')->url($this->image);
    }

    /**
     * Связь с акциями через промежуточную таблицу
     */
    public function promotions()
    {
        return $this->belongsToMany(Promotion::class, 'promotion_gifts', 'gift_catalog_id', 'promotion_id');
    }

    /**
     * Связь с promotion_gifts
     */
    public function promotionGifts()
    {
        return $this->hasMany(PromotionGift::class, 'gift_catalog_id');
    }
}







