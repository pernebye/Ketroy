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
            Schema::create('gift_certificates', function (Blueprint $table) {
                $table->id();
                $table->foreignId('sender_id')->constrained('users');
                $table->foreignId('recipient_id')->constrained('users');
                $table->string('recipient_phone'); // телефон получателя
                $table->text('congratulation_message'); // персональное поздравление
                $table->integer('nominal'); // номинал сертификата
                $table->string('barcode')->unique(); // уникальный штрих-код
                $table->timestamp('expiration_date'); // срок действия сертификата
                $table->timestamps();
            });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('gift_certificates');
    }
};
