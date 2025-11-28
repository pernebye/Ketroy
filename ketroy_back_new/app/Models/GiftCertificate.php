<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GiftCertificate extends Model
{
    use HasFactory;

    protected $fillable = [
        'sender_id', 
        'user_id', 
        'recipient_phone', 
        'congratulation_message', 
        'nominal', 
        'barcode', 
        'expiration_date'
    ];

    /**
     * Связь с моделью User (отправитель).
     */
    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    /**
     * Связь с моделью User (получатель).
     */
    public function recipient()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Метод для получения оставшихся дней до истечения сертификата.
     */
    public function getRemainingDays()
    {
        return $this->expiration_date->diffInDays(now());
    }

    /**
     * Проверка, истек ли срок действия сертификата.
     */
    public function isExpired()
    {
        return $this->expiration_date->isBefore(now());
    }

    /**
     * Генерация уникального штрих-кода.
     */
    public static function generateBarcode()
    {
        return strtoupper(uniqid('CERT-'));
    }

    /**
     * Сеттер для штрих-кода (если нужно генерировать при сохранении).
     */
    public function setBarcodeAttribute($value)
    {
        $this->attributes['barcode'] = $value ?: self::generateBarcode();
    }

    /**
     * Обработчик перед сохранением модели, если не передан штрих-код.
     */
    public static function booted()
    {
        static::creating(function ($certificate) {
            if (empty($certificate->barcode)) {
                $certificate->barcode = self::generateBarcode();
            }
        });
    }
}