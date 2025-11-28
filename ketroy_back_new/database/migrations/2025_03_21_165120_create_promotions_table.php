<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up() {
        Schema::create('promotions', function (Blueprint $table) {
            $table->id();
            $table->string('type'); 
            $table->json('settings'); 
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->boolean('is_archived')->default(false);
            $table->timestamps();
        });
    
        Schema::create('promotion_gifts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('promotion_id')->constrained()->onDelete('cascade');
            $table->string('gift_name');
            $table->string('image_path')->nullable();
            $table->integer('min_amount')->nullable();
            $table->integer('max_amount')->nullable();
            $table->timestamps();
        });
    }
    

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('promotion_gifts');
        Schema::dropIfExists('promotions');
    }
};
