<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_referral_rewards', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade'); // Новый пользователь (применивший промокод)
            $table->foreignId('referrer_id')->constrained('users')->onDelete('cascade'); // Владелец промокода
            $table->foreignId('promotion_id')->constrained()->onDelete('cascade');
            $table->json('settings_snapshot')->nullable(); // Настройки на момент применения
            $table->timestamp('applied_at')->nullable(); // Дата применения промокода
            $table->integer('purchases_rewarded')->default(0); // Сколько покупок уже учтено для бонусов
            $table->timestamps();

            // Один пользователь может применить промокод только один раз
            $table->unique(['user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_referral_rewards');
    }
};


