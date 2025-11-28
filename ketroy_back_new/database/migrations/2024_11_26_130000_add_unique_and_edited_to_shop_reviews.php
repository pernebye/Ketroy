<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * 
     * 1. Добавляем уникальный индекс на user_id + shop_id (один пользователь = один отзыв на магазин)
     * 2. Добавляем поле is_edited для пометки "отзыв был изменён"
     * 3. Добавляем поле edited_at для даты последнего редактирования
     */
    public function up(): void
    {
        Schema::table('shop_reviews', function (Blueprint $table) {
            // Пометка что отзыв был отредактирован
            $table->boolean('is_edited')->default(false)->after('rating');
            
            // Дата последнего редактирования
            $table->timestamp('edited_at')->nullable()->after('is_edited');
            
            // Уникальный индекс: один пользователь может оставить только один отзыв на один магазин
            $table->unique(['user_id', 'shop_id'], 'shop_reviews_user_shop_unique');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('shop_reviews', function (Blueprint $table) {
            $table->dropUnique('shop_reviews_user_shop_unique');
            $table->dropColumn(['is_edited', 'edited_at']);
        });
    }
};

