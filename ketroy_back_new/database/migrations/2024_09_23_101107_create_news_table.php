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
        Schema::create('news', function (Blueprint $table) {
            $table->id();
            $table->boolean('is_active')->default(true);
            $table->string('name');
            $table->text('description')->nullable();
            $table->string('city');
            $table->string('type'); // 'image' или 'video'
            $table->string('file_path'); // путь к файлу изображения или видео
            $table->string('category')->nullable();
            $table->string('height')->nullable(); // рост
            $table->string('clothing_size')->nullable(); // размер одежды
            $table->string('shoe_size')->nullable();
            $table->date('expired_at')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('news');
    }
};
