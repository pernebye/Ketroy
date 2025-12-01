<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * 
     * Таблица для отслеживания device tokens с учетом авторизации.
     * Один device_token может быть связан с несколькими пользователями,
     * но только один пользователь может быть активен на устройстве одновременно.
     */
    public function up(): void
    {
        Schema::create('device_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('token', 500); // FCM токен может быть длинным
            $table->boolean('is_active')->default(false); // Активен ли токен для этого пользователя
            $table->string('device_type')->nullable(); // ios, android, web
            $table->string('device_info')->nullable(); // Дополнительная информация об устройстве
            $table->timestamp('last_used_at')->nullable(); // Когда последний раз использовался
            $table->timestamps();

            // Уникальный индекс: один токен - один пользователь
            $table->unique(['user_id', 'token']);
            
            // Индекс для быстрого поиска активных токенов
            $table->index(['token', 'is_active']);
            $table->index(['user_id', 'is_active']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('device_tokens');
    }
};




