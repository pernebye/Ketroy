<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up() {
        Schema::table('promotion_gifts', function (Blueprint $table) {
            $table->renameColumn('image_path', 'image');
        });
    }

    public function down() {
        Schema::table('promotion_gifts', function (Blueprint $table) {
            $table->renameColumn('image', 'image_path');
        });
    }
};