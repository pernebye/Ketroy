<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('news_blocks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('news_id')->constrained()->onDelete('cascade');
            $table->string('media_path')->nullable(); // путь к изображению/видео
            $table->text('text')->nullable();          // текст
            $table->integer('order')->default(0);      // порядок отображения
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('news_blocks');
    }
};
