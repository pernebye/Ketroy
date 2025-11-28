<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Изменяем тип rating на decimal для поддержки половинчатых значений (4.5, 3.5 и т.д.)
     */
    public function up(): void
    {
        Schema::table('shop_reviews', function (Blueprint $table) {
            $table->decimal('rating', 2, 1)->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('shop_reviews', function (Blueprint $table) {
            $table->integer('rating')->nullable()->change();
        });
    }
};

