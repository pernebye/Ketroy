<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * 
     * Добавляет настройки для лотереи по датам:
     * - Push-уведомления (заголовок, текст, дата отправки)
     * - Модальное окно (заголовок, текст, изображение)
     */
    public function up(): void
    {
        Schema::table('promotions', function (Blueprint $table) {
            // Push-уведомление
            $table->string('push_title')->nullable()->after('description');
            $table->text('push_text')->nullable()->after('push_title');
            $table->datetime('push_send_at')->nullable()->after('push_text');
            $table->boolean('push_sent')->default(false)->after('push_send_at');
            
            // Модальное окно
            $table->string('modal_title')->nullable()->after('push_sent');
            $table->text('modal_text')->nullable()->after('modal_title');
            $table->string('modal_image')->nullable()->after('modal_text');
            $table->string('modal_button_text')->nullable()->after('modal_image');
        });

        // Таблица для отслеживания показанных модальных окон пользователям
        Schema::create('user_lottery_participations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('promotion_id')->constrained()->onDelete('cascade');
            $table->boolean('modal_shown')->default(false);
            $table->timestamp('modal_shown_at')->nullable();
            $table->boolean('gift_claimed')->default(false);
            $table->timestamp('gift_claimed_at')->nullable();
            $table->timestamps();
            
            $table->unique(['user_id', 'promotion_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_lottery_participations');
        
        Schema::table('promotions', function (Blueprint $table) {
            $table->dropColumn([
                'push_title',
                'push_text',
                'push_send_at',
                'push_sent',
                'modal_title',
                'modal_text',
                'modal_image',
                'modal_button_text',
            ]);
        });
    }
};

