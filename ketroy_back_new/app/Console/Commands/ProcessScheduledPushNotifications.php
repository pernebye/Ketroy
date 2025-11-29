<?php

namespace App\Console\Commands;

use App\Jobs\SendCustomPushNotificationJob;
use App\Models\PushNotification;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class ProcessScheduledPushNotifications extends Command
{
    protected $signature = 'push:process-scheduled';
    
    protected $description = 'Обработка запланированных push-уведомлений';

    public function handle(): int
    {
        $notifications = PushNotification::where('status', PushNotification::STATUS_SCHEDULED)
            ->where(function ($query) {
                $query->whereNull('scheduled_at')
                    ->orWhere('scheduled_at', '<=', Carbon::now());
            })
            ->get();

        if ($notifications->isEmpty()) {
            $this->info('Нет запланированных уведомлений для отправки');
            return self::SUCCESS;
        }

        $this->info("Найдено {$notifications->count()} уведомлений для отправки");

        foreach ($notifications as $notification) {
            $this->info("Запускаем отправку push notification ID: {$notification->id}");
            
            SendCustomPushNotificationJob::dispatch($notification->id);
            
            Log::info("ProcessScheduledPush: Запущена отправка push notification ID {$notification->id}");
        }

        $this->info('Все уведомления поставлены в очередь');

        return self::SUCCESS;
    }
}



