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
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('surname');
            $table->string('city')->nullable()->change(); // город
            $table->date('birthdate')->nullable()->change(); // день рождения
            $table->string('height')->nullable()->change(); // рост
            $table->string('clothing_size')->nullable()->change(); // размер одежды
            $table->string('shoe_size')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('surname');
            $table->string('city')->nullable(false)->change(); // город
            $table->date('birthdate')->nullable(false)->change(); // день рождения
            $table->string('height')->nullable(false)->change(); // рост
            $table->string('clothing_size')->nullable(false)->change(); // размер одежды
            $table->string('shoe_size')->nullable(false)->change();
        });
    }
};
