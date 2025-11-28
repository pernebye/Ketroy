<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Purchase extends Model
{
    
    use HasFactory;

    // Массово заполняемые поля
    protected $fillable = [
        'user_id',
        'item',
        'quantity',
        'total_price',
        'purchased_at',
    ];

    // Связь с пользователем
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Связь с транзакциями
    public function transactions()
    {
        return $this->morphMany(Transaction::class, 'related');
    }
}
