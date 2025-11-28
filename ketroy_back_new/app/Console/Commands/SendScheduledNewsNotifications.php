<?php

namespace App\Console\Commands;

use App\Jobs\SendNewsPushJob;
use App\Models\News;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class SendScheduledNewsNotifications extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'news:send-scheduled-notifications';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Отправляет push-уведомления для новостей, у которых published_at наступает сегодня';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $today = Carbon::today('Asia/Almaty');
        
        Log::info('SendScheduledNewsNotifications: Проверка новостей для отправки уведомлений', [
            'date' => $today->toDateString(),
        ]);

        // Находим новости, которые:
        // 1. Активны (is_active = true)
        // 2. Не архивированы
        // 3. published_at = сегодня (в часовом поясе Алматы)
        // 4. Уведомление еще не отправлено (notification_sent = false)
        // 5. Не истекли (expired_at null или >= сегодня)
        $news = News::where('is_active', true)
            ->where('is_archived', false)
            ->where('notification_sent', false)
            ->whereDate('published_at', $today)
            ->where(function ($query) use ($today) {
                $query->whereNull('expired_at')
                      ->orWhere('expired_at', '>=', $today);
            })
            ->get();

        if ($news->isEmpty()) {
            $this->info('Нет новостей для отправки уведомлений');
            Log::info('SendScheduledNewsNotifications: Нет новостей для отправки');
            return Command::SUCCESS;
        }

        $this->info("Найдено {$news->count()} новостей для отправки уведомлений");

        foreach ($news as $newsItem) {
            try {
                SendNewsPushJob::dispatch($newsItem->id);
                
                $this->info("Запущена отправка уведомлений для новости ID: {$newsItem->id} - {$newsItem->name}");
                Log::info("SendScheduledNewsNotifications: Запущена отправка для новости", [
                    'news_id' => $newsItem->id,
                    'name' => $newsItem->name,
                    'published_at' => $newsItem->published_at,
                ]);
            } catch (\Exception $e) {
                $this->error("Ошибка при запуске отправки для новости ID: {$newsItem->id}");
                Log::error("SendScheduledNewsNotifications: Ошибка отправки", [
                    'news_id' => $newsItem->id,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        $this->info('Завершено');
        return Command::SUCCESS;
    }
}

