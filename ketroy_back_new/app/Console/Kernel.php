<?php

namespace App\Console;

use App\Console\Commands\AnalyzePromotions;
use App\Console\Commands\CheckAccumulationGifts;
use App\Console\Commands\CheckDateBasedGifts;
use App\Console\Commands\SendBirthdayNotifications;
use App\Console\Commands\SendLotteryNotifications;
use App\Console\Commands\SendScheduledNewsNotifications;
use App\Console\Commands\SyncClientsPurchases;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    protected $commands = [
        CheckAccumulationGifts::class,
        CheckDateBasedGifts::class,
        SyncClientsPurchases::class,
        SendBirthdayNotifications::class,
        SendLotteryNotifications::class,
        AnalyzePromotions::class,
        SendScheduledNewsNotifications::class,
    ];

    protected function commands(): void
    {
        $this->load(__DIR__ . '/Commands');
        require base_path('routes/console.php');
    }


    protected function schedule(Schedule $schedule): void
    {
        // Запуск каждый час для проверки расписания уведомлений о дне рождения
        // (каждое уведомление имеет свой час отправки, команда сама определяет нужно ли отправлять)
        $schedule->command('notify:birthday')->hourly();
        $schedule->command('analytics:analyze-promotions')->daily();
        $schedule->command('gifts:date-based')->dailyAt('05:00');
        $schedule->command('gifts:accumulation')->everySixHours();
        $schedule->command('app:sync-clients-purchases')->everyTwoHours();
        
        // Проверка лотерейных push-уведомлений каждые 5 минут
        $schedule->command('lottery:send-notifications')->everyFiveMinutes();
        
        // Отправка уведомлений о новостях в 10:00 по Алматы
        // Для новостей с запланированной датой публикации (published_at)
        $schedule->command('news:send-scheduled-notifications')
            ->dailyAt('10:00')
            ->timezone('Asia/Almaty')
            ->withoutOverlapping()
            ->onOneServer();
    }
}
