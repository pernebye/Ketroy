<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Добавляем новые JSON столбцы
        Schema::table('news', function (Blueprint $table) {
            $table->jsonb('cities')->nullable()->after('city');
            $table->jsonb('categories')->nullable()->after('category');
        });

        // Конвертируем существующие данные в JSON формат (PostgreSQL)
        // Для города
        DB::statement("UPDATE news SET cities = CASE 
            WHEN city IS NULL OR city = '' THEN '[]'::jsonb
            ELSE jsonb_build_array(city)
        END");
        
        // Для категории
        DB::statement("UPDATE news SET categories = CASE 
            WHEN category IS NULL OR category = '' OR category = 'null' THEN '[]'::jsonb
            ELSE jsonb_build_array(category)
        END");

        // Удаляем старые столбцы
        Schema::table('news', function (Blueprint $table) {
            $table->dropColumn(['city', 'category']);
        });

        // Переименовываем новые столбцы
        Schema::table('news', function (Blueprint $table) {
            $table->renameColumn('cities', 'city');
            $table->renameColumn('categories', 'category');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Создаём временные строковые столбцы
        Schema::table('news', function (Blueprint $table) {
            $table->string('city_str')->nullable();
            $table->string('category_str')->nullable();
        });

        // Конвертируем JSON обратно в строки (берём первый элемент)
        DB::statement("UPDATE news SET city_str = city->>0");
        DB::statement("UPDATE news SET category_str = category->>0");

        // Удаляем JSON столбцы
        Schema::table('news', function (Blueprint $table) {
            $table->dropColumn(['city', 'category']);
        });

        // Переименовываем
        Schema::table('news', function (Blueprint $table) {
            $table->renameColumn('city_str', 'city');
            $table->renameColumn('category_str', 'category');
        });
    }
};
