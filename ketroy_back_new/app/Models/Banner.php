<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * @OA\Schema(
 *     schema="Banner",
 *     type="object",
 *     title="Banner",
 *     description="Баннер для отображения в приложении",
 *     required={"id", "title", "image", "city"},
 *     @OA\Property(property="id", type="integer", example=1),
 *     @OA\Property(property="title", type="string", example="Супер акция"),
 *     @OA\Property(property="image", type="string", format="url", example="https://example.com/banner.jpg"),
 *     @OA\Property(property="city", type="string", example="Almaty")
 * )
 */
class Banner extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'cities',
        'type',
        'file_path',
        'is_active',
        'start_date',
        'expired_at',
        'sort_order',
    ];

    protected $casts = [
        'cities' => 'array',
        'start_date' => 'date',
        'expired_at' => 'date',
        'is_active' => 'boolean',
        'sort_order' => 'integer',
    ];
}
