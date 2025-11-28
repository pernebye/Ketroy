<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Удаляем min_amount и max_amount из promotion_gifts.
     * Теперь порог покупок хранится в settings акции, а выбор подарка делает пользователь.
     */
    public function up(): void
    {
        Schema::table('promotion_gifts', function (Blueprint $table) {
            if (Schema::hasColumn('promotion_gifts', 'min_amount')) {
                $table->dropColumn('min_amount');
            }
            if (Schema::hasColumn('promotion_gifts', 'max_amount')) {
                $table->dropColumn('max_amount');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('promotion_gifts', function (Blueprint $table) {
            $table->integer('min_amount')->nullable();
            $table->integer('max_amount')->nullable();
        });
    }
};




