<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Shop extends Model
{
    use HasFactory;

    protected $fillable = [
        'is_active',
        'name',
        'description',
        'city',
        'file_path',
        'opening_hours',
        'address',
        'two_gis_address',
        'instagram',
        'whatsapp'
    ];

    public function reviews(): HasMany
    {
        return $this->hasMany(ShopReview::class);
    }
}
