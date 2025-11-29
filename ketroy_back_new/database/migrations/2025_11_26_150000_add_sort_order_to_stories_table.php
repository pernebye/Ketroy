<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('stories', function (Blueprint $table) {
            $table->integer('sort_order')->default(0)->after('cover_path');
        });

        // Инициализируем sort_order для существующих записей на основе created_at
        DB::statement('
            UPDATE stories 
            SET sort_order = sub.row_num 
            FROM (
                SELECT id, ROW_NUMBER() OVER (PARTITION BY actual_group ORDER BY created_at ASC) as row_num
                FROM stories
            ) sub 
            WHERE stories.id = sub.id
        ');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('stories', function (Blueprint $table) {
            $table->dropColumn('sort_order');
        });
    }
};





