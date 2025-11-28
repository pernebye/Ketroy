<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('loyalty_levels', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // Название уровня (например, "Новичок", "Бронза")
            $table->string('icon')->nullable(); // Иконка/эмодзи уровня
            $table->string('color')->nullable(); // Цвет уровня (hex)
            $table->unsignedBigInteger('min_purchase_amount')->default(0); // Минимальная сумма покупок для достижения
            $table->integer('order')->default(0); // Порядок сортировки
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Таблица наград за достижение уровня
        Schema::create('loyalty_level_rewards', function (Blueprint $table) {
            $table->id();
            $table->foreignId('loyalty_level_id')->constrained()->onDelete('cascade');
            $table->enum('reward_type', ['discount', 'bonus', 'gift_choice']); // Тип награды
            
            // Для скидки
            $table->integer('discount_percent')->nullable();
            
            // Для бонусов
            $table->unsignedBigInteger('bonus_amount')->nullable();
            
            // Описание награды
            $table->string('description')->nullable();
            
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Таблица подарков для выбора (gift_choice)
        Schema::create('loyalty_reward_gifts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('loyalty_level_reward_id')->constrained()->onDelete('cascade');
            $table->foreignId('gift_catalog_id')->constrained('gift_catalog')->onDelete('cascade');
            $table->timestamps();
        });

        // История получения наград пользователями
        Schema::create('user_loyalty_rewards', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('loyalty_level_id')->constrained()->onDelete('cascade');
            $table->foreignId('loyalty_level_reward_id')->nullable()->constrained()->onDelete('set null');
            $table->foreignId('selected_gift_id')->nullable()->constrained('gift_catalog')->onDelete('set null');
            $table->timestamp('achieved_at');
            $table->timestamp('reward_claimed_at')->nullable();
            $table->timestamps();
            
            // Пользователь может получить награду за уровень только один раз
            $table->unique(['user_id', 'loyalty_level_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_loyalty_rewards');
        Schema::dropIfExists('loyalty_reward_gifts');
        Schema::dropIfExists('loyalty_level_rewards');
        Schema::dropIfExists('loyalty_levels');
    }
};

