<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     * 
     * Создаём независимый каталог подарков.
     * Подарки теперь могут использоваться в любых акциях многократно.
     */
    public function up(): void
    {
        // 1. Создаём таблицу каталога подарков
        Schema::create('gift_catalog', function (Blueprint $table) {
            $table->id();
            $table->string('name');           // Название подарка (Галстук, Рубашка и т.д.)
            $table->string('image')->nullable(); // Путь к изображению
            $table->text('description')->nullable(); // Описание подарка
            $table->boolean('is_active')->default(true); // Активен ли подарок
            $table->timestamps();
        });

        // 2. Переносим существующие подарки из promotion_gifts в каталог
        $existingGifts = DB::table('promotion_gifts')
            ->select('gift_name', 'image')
            ->distinct()
            ->get();

        foreach ($existingGifts as $gift) {
            DB::table('gift_catalog')->insert([
                'name' => $gift->gift_name,
                'image' => $gift->image,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // 3. Добавляем колонку gift_catalog_id в promotion_gifts
        Schema::table('promotion_gifts', function (Blueprint $table) {
            $table->foreignId('gift_catalog_id')->nullable()->after('promotion_id');
        });

        // 4. Связываем существующие записи с каталогом
        $promotionGifts = DB::table('promotion_gifts')->get();
        foreach ($promotionGifts as $pg) {
            $catalogItem = DB::table('gift_catalog')
                ->where('name', $pg->gift_name)
                ->first();
            
            if ($catalogItem) {
                DB::table('promotion_gifts')
                    ->where('id', $pg->id)
                    ->update(['gift_catalog_id' => $catalogItem->id]);
            }
        }

        // 5. Удаляем старые колонки из promotion_gifts
        Schema::table('promotion_gifts', function (Blueprint $table) {
            $table->dropColumn(['gift_name', 'image']);
        });

        // 6. Добавляем внешний ключ
        Schema::table('promotion_gifts', function (Blueprint $table) {
            $table->foreign('gift_catalog_id')
                ->references('id')
                ->on('gift_catalog')
                ->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Восстанавливаем колонки
        Schema::table('promotion_gifts', function (Blueprint $table) {
            $table->dropForeign(['gift_catalog_id']);
            $table->string('gift_name')->nullable();
            $table->string('image')->nullable();
        });

        // Копируем данные обратно
        $promotionGifts = DB::table('promotion_gifts')
            ->join('gift_catalog', 'promotion_gifts.gift_catalog_id', '=', 'gift_catalog.id')
            ->select('promotion_gifts.id', 'gift_catalog.name', 'gift_catalog.image')
            ->get();

        foreach ($promotionGifts as $pg) {
            DB::table('promotion_gifts')
                ->where('id', $pg->id)
                ->update([
                    'gift_name' => $pg->name,
                    'image' => $pg->image,
                ]);
        }

        Schema::table('promotion_gifts', function (Blueprint $table) {
            $table->dropColumn('gift_catalog_id');
        });

        Schema::dropIfExists('gift_catalog');
    }
};






