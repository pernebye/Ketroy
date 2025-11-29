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
        Schema::table('gifts', function (Blueprint $table) {
            if (!Schema::hasColumn('gifts', 'issuance_qr_code')) {
                $table->string('issuance_qr_code')->nullable()->after('issued_at');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('gifts', function (Blueprint $table) {
            if (Schema::hasColumn('gifts', 'issuance_qr_code')) {
                $table->dropColumn('issuance_qr_code');
            }
        });
    }
};


