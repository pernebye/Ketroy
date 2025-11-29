<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ActualGroup extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'image',
        'is_welcome',
        'is_system',
        'sort_order',
    ];

    protected $casts = [
        'is_welcome' => 'boolean',
        'is_system' => 'boolean',
    ];

    /**
     * Получить все истории этой группы
     */
    public function stories(): HasMany
    {
        return $this->hasMany(Story::class, 'actual_group', 'name');
    }
}






