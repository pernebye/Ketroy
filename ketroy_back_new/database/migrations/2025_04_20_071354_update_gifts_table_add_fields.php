<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('gifts', function (Blueprint $table) {
            $table->boolean('is_viewed')->default(false);
            $table->string('image')->nullable();
            $table->foreignId('promotion_id')->nullable()->constrained()->nullOnDelete();
        });
    }

    public function down()
    {
        Schema::table('gifts', function (Blueprint $table) {
            $table->dropColumn(['is_viewed', 'image']);
            $table->dropForeign(['promotion_id']);
            $table->dropColumn('promotion_id');
        });
    }
};
