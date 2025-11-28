<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Story extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'cities',
        'actual_group',
        'type',
        'file_path',
        'is_active',
        'expired_at',
        'cover_path',
        'sort_order',
    ];

    protected $casts = [
        'cities' => 'array',
        'is_active' => 'boolean',
    ];
}
