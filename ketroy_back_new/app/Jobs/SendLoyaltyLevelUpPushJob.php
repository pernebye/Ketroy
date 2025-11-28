<?php

namespace App\Jobs;

use App\Models\DeviceToken;
use App\Models\User;
use App\Models\LoyaltyLevel;
use App\Services\FirebaseService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Job для отправки push-уведомления о повышении уровня лояльности
 */
class SendLoyaltyLevelUpPushJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 30;

    protected User $user;
    protected LoyaltyLevel $level;
    protected int $levelsCount;

    /**
     * Create a new job instance.
     */
    public function __construct(User $user, LoyaltyLevel $level, int $levelsCount = 1)
    {
        $this->user = $user;
        $this->level = $level;
        $this->levelsCount = $levelsCount;
    }

    /**
     * Execute the job.
     */
    public function handle(FirebaseService $firebase): void
    {
        // Получаем АКТИВНЫЙ токен пользователя
        $activeToken = DeviceToken::getActiveTokenForUser($this->user->id);
        
        if (empty($activeToken)) {
            Log::info('[LoyaltyPush] No active device token', ['user_id' => $this->user->id]);
            return;
        }

        $icon = $this->level->icon ?? '🏆';
        
        // Формируем заголовок
        $title = $this->levelsCount > 1 
            ? "🎉 Поздравляем! Новые уровни!"
            : "🎉 Поздравляем! Новый уровень!";

        // Формируем сообщение
        $body = $this->levelsCount > 1
            ? "Вы достигли {$this->levelsCount} новых уровней! Ваш текущий уровень: {$icon} {$this->level->name}"
            : "Вы достигли уровня {$icon} {$this->level->name}! Проверьте свои награды в приложении.";

        try {
            $badge = $this->user->notifications()->where('is_read', false)->count() + 1;
            
            $firebase->sendPushNotification(
                null,
                $badge,
                'loyalty',
                $activeToken, // Используем активный токен
                $title,
                $body,
                [
                    'type' => 'loyalty_level_up',
                    'level_id' => (string) $this->level->id,
                    'level_name' => $this->level->name,
                    'level_icon' => $icon,
                    'levels_count' => (string) $this->levelsCount,
                ]
            );

            Log::info('[LoyaltyPush] Push sent', [
                'user_id' => $this->user->id,
                'level' => $this->level->name,
            ]);

        } catch (\Exception $e) {
            Log::error('[LoyaltyPush] Failed to send push', [
                'user_id' => $this->user->id,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }
}

