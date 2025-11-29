<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('gifts', function (Blueprint $table) {
            // Статус подарка: pending (ожидает выбора), selected (выбран), activated (активирован в магазине), issued (выдан)
            $table->string('status')->default('pending')->after('is_activated');
            
            // Группа подарков - связывает несколько подарков отправленных вместе для выбора
            $table->string('gift_group_id')->nullable()->after('status');
            
            // ID подарка из каталога (для связи с оригинальным подарком)
            $table->foreignId('gift_catalog_id')->nullable()->after('gift_group_id')->constrained('gift_catalog')->nullOnDelete();
            
            // Дата выбора подарка пользователем
            $table->timestamp('selected_at')->nullable()->after('gift_catalog_id');
            
            // Дата выдачи подарка в магазине
            $table->timestamp('issued_at')->nullable()->after('selected_at');
            
            // Индексы для быстрого поиска
            $table->index('status');
            $table->index('gift_group_id');
        });
    }

    public function down(): void
    {
        Schema::table('gifts', function (Blueprint $table) {
            $table->dropIndex(['status']);
            $table->dropIndex(['gift_group_id']);
            $table->dropForeign(['gift_catalog_id']);
            $table->dropColumn(['status', 'gift_group_id', 'gift_catalog_id', 'selected_at', 'issued_at']);
        });
    }
};






