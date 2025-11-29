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
        // Сначала конвертируем существующие данные city в JSON формат
        $banners = DB::table('banners')->get();
        foreach ($banners as $banner) {
            $cities = $banner->city ? [$banner->city] : ['Все'];
            DB::table('banners')
                ->where('id', $banner->id)
                ->update(['city' => json_encode($cities, JSON_UNESCAPED_UNICODE)]);
        }

        // Переименовываем колонку city в cities
        Schema::table('banners', function (Blueprint $table) {
            $table->renameColumn('city', 'cities');
        });

        // Удаляем subtitle если существует
        if (Schema::hasColumn('banners', 'subtitle')) {
            Schema::table('banners', function (Blueprint $table) {
                $table->dropColumn('subtitle');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('banners', function (Blueprint $table) {
            $table->renameColumn('cities', 'city');
            $table->string('subtitle')->nullable()->after('name');
        });
    }
};






