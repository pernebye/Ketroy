<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class News extends Model
{
    use HasFactory;

    protected $fillable = [
        'is_active',
        'is_archived',
        'notification_sent',
        'name',
        'description',
        'category',
        'height',
        'clothing_size',
        'shoe_size',
        'city',
        'type',
        'file_path',
        'expired_at',
        'published_at',
        'sort_order',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'is_archived' => 'boolean',
        'notification_sent' => 'boolean',
        'city' => 'array',
        'category' => 'array',
    ];

    public function blocks()
    {
        return $this->hasMany(NewsBlock::class);
    }

    /**
     * Проверяет, соответствует ли новость указанному городу
     */
    public function matchesCity(?string $city): bool
    {
        if (!$city || $city === 'Все') return true;
        
        $cities = $this->city ?? [];
        return in_array('Все', $cities) || in_array($city, $cities);
    }

    /**
     * Проверяет, соответствует ли новость указанной категории
     */
    public function matchesCategory(?string $category): bool
    {
        if (!$category || $category === 'Все') return true;
        
        $categories = $this->category ?? [];
        return in_array('Все', $categories) || in_array($category, $categories);
    }
}
