<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NewsBlock extends Model
{
    protected $fillable = [
        'media_path',
        'text',
        'order',
        'resolution'
    ];

    public function news()
    {
        return $this->belongsTo(News::class);
    }
}
