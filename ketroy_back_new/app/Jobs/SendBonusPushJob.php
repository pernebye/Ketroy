<?php

namespace App\Jobs;

use App\Models\DeviceToken;
use App\Models\User;
use App\Services\FirebaseService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

class SendBonusPushJob implements ShouldQueue
{
    use Queueable;
    
    protected int $bonusAmount;
    protected int $userId;
    protected string $operation; // 'add' или 'write-off'
    protected bool $withDelay;   // true если бонусы с отсрочкой 14 дней

    /**
     * Create a new job instance.
     * 
     * @param int $bonus Количество бонусов
     * @param int $userId ID пользователя (не объект, для сериализации)
     * @param string $operation Тип операции: 'add' (начисление) или 'write-off' (списание)
     * @param bool $withDelay true если бонусы будут доступны через 14 дней
     */
    public function __construct(int $bonus, int $userId, string $operation = 'add', bool $withDelay = false)
    {
        $this->userId = $userId;
        $this->bonusAmount = $bonus;
        $this->operation = $operation;
        $this->withDelay = $withDelay;
    }

    /**
     * Execute the job.
     */
    public function handle(FirebaseService $firebaseService): void
    {
        $user = User::find($this->userId);
        
        if (!$user) {
            Log::warning("[BonusPush] User not found: {$this->userId}");
            return;
        }
        
        // Получаем АКТИВНЫЙ токен пользователя (только если авторизован на устройстве)
        $activeToken = DeviceToken::getActiveTokenForUser($this->userId);
        
        if (empty($activeToken)) {
            Log::info("[BonusPush] User {$this->userId} has no active device token, skipping push");
            return;
        }

        // Формируем текст уведомления в зависимости от операции и отсрочки
        if ($this->operation === 'add') {
            $title = 'Бонусы начислены! 🎉';
            if ($this->withDelay) {
                $body = "Вам начислено {$this->bonusAmount} баллов. Они будут доступны через 14 дней.";
            } else {
                $body = "Вам начислено {$this->bonusAmount} баллов. Спасибо за покупку!";
            }
        } else {
            $title = 'Бонусы списаны';
            $body = "С вашего счёта списано {$this->bonusAmount} баллов.";
        }

        // НЕ создаём уведомление здесь!
        // Уведомление создаётся автоматически через FirebaseService event (NotificationSendedEvent)
        // Это предотвращает дублирование записей в БД

        // Считаем непрочитанные для badge (до создания нового)
        $badge = $user->notifications()->where('is_read', false)->count() + 1;

        // Отправляем push — FirebaseService создаст уведомление в БД через event
        $success = $firebaseService->sendPushNotification(
            null, // notification_id будет создан автоматически
            $badge,
            'bonus',
            $activeToken, // Используем активный токен вместо legacy device_token
            $title,
            $body,
            [
                'type' => 'bonus',
                'operation' => $this->operation,
                'amount' => $this->bonusAmount,
                'withDelay' => $this->withDelay,
            ]
        );

        if ($success) {
            Log::info("[BonusPush] Push sent to user {$this->userId}: {$this->operation} {$this->bonusAmount} bonuses, withDelay: " . ($this->withDelay ? 'yes' : 'no'));
        } else {
            Log::warning("[BonusPush] Failed to send push to user {$this->userId}");
        }
    }
}
