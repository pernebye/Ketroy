<?php

use App\Models\User;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

return new class extends Migration
{
    /**
     * Run the migrations.
     * 
     * Мигрируем существующие device_token из таблицы users в device_tokens.
     * Все существующие токены помечаются как активные.
     */
    public function up(): void
    {
        // Получаем всех пользователей с device_token
        $users = DB::table('users')
            ->whereNotNull('device_token')
            ->where('device_token', '!=', '')
            ->get(['id', 'device_token']);

        $count = 0;

        foreach ($users as $user) {
            // Проверяем, нет ли уже такой записи
            $exists = DB::table('device_tokens')
                ->where('user_id', $user->id)
                ->where('token', $user->device_token)
                ->exists();

            if (!$exists) {
                DB::table('device_tokens')->insert([
                    'user_id' => $user->id,
                    'token' => $user->device_token,
                    'is_active' => true, // Считаем все существующие токены активными
                    'device_type' => null,
                    'device_info' => 'Migrated from users table',
                    'last_used_at' => now(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
                $count++;
            }
        }

        Log::info("[Migration] Migrated {$count} device tokens from users table");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Удаляем только те токены, которые были мигрированы
        DB::table('device_tokens')
            ->where('device_info', 'Migrated from users table')
            ->delete();
    }
};

