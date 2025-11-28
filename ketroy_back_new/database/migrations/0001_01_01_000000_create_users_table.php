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
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('surname'); // фамилия
            $table->string('phone')->unique(); // номер телефона
            $table->string('avatar_image')->nullable();
            $table->string('country_code');
            $table->string('city'); // город
            $table->date('birthdate'); // день рождения
            $table->string('height'); // рост
            $table->string('clothing_size'); // размер одежды
            $table->string('shoe_size'); // размер обуви
            $table->string('verification_code')->nullable(); // код подтверждения
            $table->timestamp('code_expires_at')->nullable(); // дата и время истечения кода
            $table->rememberToken();
            $table->timestamps();
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('users');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('sessions');
    }
};
