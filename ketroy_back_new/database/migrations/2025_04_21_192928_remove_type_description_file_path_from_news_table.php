<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('news', function (Blueprint $table) {
            $table->dropColumn(['type', 'description', 'file_path']);
        });
    }

    public function down(): void
    {
        Schema::table('news', function (Blueprint $table) {
            $table->string('type')->nullable();
            $table->text('description')->nullable();
            $table->string('file_path')->nullable();
        });
    }
};
