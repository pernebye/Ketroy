<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class PromoCode extends Model
{
    protected $fillable = ['code', 'user_id'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public static function generateUniqueCode($length = 6): string
    {
        do {
            $code = strtoupper(Str::random($length)); // Пример: 8 символов, A-Z, 0-9
        } while (self::where('code', $code)->exists());

        return $code;
    }
}
