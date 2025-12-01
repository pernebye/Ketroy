<?php

namespace App\Console\Commands;

use App\Jobs\SendLotteryPushNotificationsJob;
use Illuminate\Console\Command;

class SendLotteryNotifications extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'lottery:send-notifications';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Отправляет push-уведомления для лотерей по расписанию';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $this->info('Dispatching lottery push notifications job...');
        
        SendLotteryPushNotificationsJob::dispatch();
        
        $this->info('Job dispatched successfully!');
        
        return Command::SUCCESS;
    }
}




