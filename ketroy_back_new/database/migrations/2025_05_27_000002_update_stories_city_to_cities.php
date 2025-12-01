<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Конвертируем существующие данные city в JSON формат
        $stories = DB::table('stories')->get();
        foreach ($stories as $story) {
            $cities = $story->city ? [$story->city] : ['Все'];
            DB::table('stories')
                ->where('id', $story->id)
                ->update(['city' => json_encode($cities, JSON_UNESCAPED_UNICODE)]);
        }

        // Переименовываем колонку
        Schema::table('stories', function (Blueprint $table) {
            $table->renameColumn('city', 'cities');
        });
    }

    public function down(): void
    {
        Schema::table('stories', function (Blueprint $table) {
            $table->renameColumn('cities', 'city');
        });
    }
};







