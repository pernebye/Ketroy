<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id'); // ID пользователя
            $table->string('type'); // Тип транзакции (например, 'purchase', 'refund')
            $table->decimal('amount', 10, 2); // Сумма транзакции
            $table->unsignedBigInteger('related_id')->nullable(); // Связанный объект (например, ID покупки или возврата)
            $table->string('related_type')->nullable(); // Тип связанного объекта
            $table->timestamps();

            // Связь с таблицей пользователей
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
