<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

/**
 * Миграция для оптимизации под PostgreSQL
 *
 * - Создаёт ENUM типы
 * - Добавляет индексы для частых запросов
 * - Оптимизирует типы данных
 */
return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Только для PostgreSQL
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }

        // ============================================
        // СОЗДАНИЕ ENUM ТИПОВ
        // ============================================

        // Типы для transactions
        DB::statement("DO $$ BEGIN
            CREATE TYPE transaction_type_enum AS ENUM ('add', 'write-off');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $$;");

        // Типы для контента
        DB::statement("DO $$ BEGIN
            CREATE TYPE content_type_enum AS ENUM ('image', 'video');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $$;");

        // Типы для блоков новостей
        DB::statement("DO $$ BEGIN
            CREATE TYPE news_block_type_enum AS ENUM ('text', 'image', 'video', 'youtube');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $$;");

        // ============================================
        // ДОБАВЛЕНИЕ ИНДЕКСОВ
        // ============================================

        // Индексы для users
        Schema::table('users', function (Blueprint $table) {
            // Индекс для поиска по телефону (уже есть unique)
            // Индекс для поиска по городу
            $table->index('city', 'idx_users_city');
            // Индекс для сортировки по дате создания
            $table->index('created_at', 'idx_users_created_at');
        });

        // Индексы для transactions
        if (Schema::hasTable('transactions')) {
            Schema::table('transactions', function (Blueprint $table) {
                $table->index('user_id', 'idx_transactions_user_id');
                $table->index('created_at', 'idx_transactions_created_at');
                $table->index(['user_id', 'type'], 'idx_transactions_user_type');
            });
        }

        // Индексы для purchases
        if (Schema::hasTable('purchases')) {
            Schema::table('purchases', function (Blueprint $table) {
                $table->index('user_id', 'idx_purchases_user_id');
                $table->index('purchased_at', 'idx_purchases_purchased_at');
            });
        }

        // Индексы для gifts
        if (Schema::hasTable('gifts')) {
            Schema::table('gifts', function (Blueprint $table) {
                $table->index('user_id', 'idx_gifts_user_id');
                $table->index('is_activated', 'idx_gifts_is_activated');
                $table->index(['user_id', 'is_activated'], 'idx_gifts_user_activated');
            });
        }

        // Индексы для notifications
        if (Schema::hasTable('notifications')) {
            Schema::table('notifications', function (Blueprint $table) {
                $table->index('user_id', 'idx_notifications_user_id');
                $table->index('created_at', 'idx_notifications_created_at');
            });
        }

        // Индексы для news
        if (Schema::hasTable('news')) {
            Schema::table('news', function (Blueprint $table) {
                $table->index('published_at', 'idx_news_published_at');
                $table->index('created_at', 'idx_news_created_at');
            });
        }

        // Индексы для banners
        if (Schema::hasTable('banners')) {
            Schema::table('banners', function (Blueprint $table) {
                $table->index('created_at', 'idx_banners_created_at');
            });
        }

        // Индексы для shops
        if (Schema::hasTable('shops')) {
            Schema::table('shops', function (Blueprint $table) {
                if (Schema::hasColumn('shops', 'is_active')) {
                    $table->index('is_active', 'idx_shops_is_active');
                }
            });
        }

        // Индексы для promo_codes
        if (Schema::hasTable('promo_codes')) {
            Schema::table('promo_codes', function (Blueprint $table) {
                $table->index('user_id', 'idx_promo_codes_user_id');
            });
        }

        // Индексы для analytics_events
        if (Schema::hasTable('analytics_events')) {
            Schema::table('analytics_events', function (Blueprint $table) {
                $table->index('created_at', 'idx_analytics_events_created_at');
                $table->index('event_type', 'idx_analytics_events_type');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }

        // Удаляем индексы
        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex('idx_users_city');
            $table->dropIndex('idx_users_created_at');
        });

        if (Schema::hasTable('transactions')) {
            Schema::table('transactions', function (Blueprint $table) {
                $table->dropIndex('idx_transactions_user_id');
                $table->dropIndex('idx_transactions_created_at');
                $table->dropIndex('idx_transactions_user_type');
            });
        }

        if (Schema::hasTable('purchases')) {
            Schema::table('purchases', function (Blueprint $table) {
                $table->dropIndex('idx_purchases_user_id');
                $table->dropIndex('idx_purchases_purchased_at');
            });
        }

        if (Schema::hasTable('gifts')) {
            Schema::table('gifts', function (Blueprint $table) {
                $table->dropIndex('idx_gifts_user_id');
                $table->dropIndex('idx_gifts_is_activated');
                $table->dropIndex('idx_gifts_user_activated');
            });
        }

        if (Schema::hasTable('notifications')) {
            Schema::table('notifications', function (Blueprint $table) {
                $table->dropIndex('idx_notifications_user_id');
                $table->dropIndex('idx_notifications_created_at');
            });
        }

        if (Schema::hasTable('news')) {
            Schema::table('news', function (Blueprint $table) {
                $table->dropIndex('idx_news_published_at');
                $table->dropIndex('idx_news_created_at');
            });
        }

        if (Schema::hasTable('banners')) {
            Schema::table('banners', function (Blueprint $table) {
                $table->dropIndex('idx_banners_created_at');
            });
        }

        if (Schema::hasTable('shops')) {
            Schema::table('shops', function (Blueprint $table) {
                $table->dropIndex('idx_shops_is_active');
            });
        }

        if (Schema::hasTable('promo_codes')) {
            Schema::table('promo_codes', function (Blueprint $table) {
                $table->dropIndex('idx_promo_codes_user_id');
            });
        }

        if (Schema::hasTable('analytics_events')) {
            Schema::table('analytics_events', function (Blueprint $table) {
                $table->dropIndex('idx_analytics_events_created_at');
                $table->dropIndex('idx_analytics_events_type');
            });
        }

        // Удаляем ENUM типы
        DB::statement('DROP TYPE IF EXISTS transaction_type_enum CASCADE;');
        DB::statement('DROP TYPE IF EXISTS content_type_enum CASCADE;');
        DB::statement('DROP TYPE IF EXISTS news_block_type_enum CASCADE;');
    }
};






