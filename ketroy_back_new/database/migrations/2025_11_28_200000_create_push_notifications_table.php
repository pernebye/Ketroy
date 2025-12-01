<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('push_notifications', function (Blueprint $table) {
            $table->id();
            
            // Основная информация
            $table->string('title');
            $table->text('body');
            
            // Статус отправки: draft, scheduled, sending, sent, failed, cancelled
            $table->string('status')->default('draft');
            
            // Планирование отправки
            $table->timestamp('scheduled_at')->nullable(); // null = отправить сразу
            $table->timestamp('sent_at')->nullable();
            
            // Таргетинг (JSON массивы для множественного выбора)
            $table->json('target_cities')->nullable(); // ['Алматы', 'Астана']
            $table->json('target_clothing_sizes')->nullable(); // ['S', 'M', 'L']
            $table->json('target_shoe_sizes')->nullable(); // ['38', '39', '40']
            
            // Статистика
            $table->integer('recipients_count')->default(0); // Кол-во получателей
            $table->integer('sent_count')->default(0); // Успешно отправлено
            $table->integer('failed_count')->default(0); // Ошибки при отправке
            
            // Кто создал
            $table->foreignId('created_by')->nullable()->constrained('admins')->nullOnDelete();
            
            // Метаданные
            $table->text('error_message')->nullable();
            $table->timestamps();
            
            // Индексы для поиска
            $table->index('status');
            $table->index('scheduled_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('push_notifications');
    }
};




