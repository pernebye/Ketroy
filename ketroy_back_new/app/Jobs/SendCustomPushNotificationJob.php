<?php

namespace App\Jobs;

use App\Models\DeviceToken;
use App\Models\Notification;
use App\Models\PushNotification;
use App\Services\FirebaseService;
use Carbon\Carbon;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendCustomPushNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected int $pushNotificationId;

    /**
     * Количество попыток выполнения задания
     */
    public int $tries = 3;

    /**
     * Время ожидания между попытками (секунды)
     */
    public int $backoff = 60;

    /**
     * Таймаут выполнения (5 минут для большого количества уведомлений)
     */
    public int $timeout = 300;

    public function __construct(int $pushNotificationId)
    {
        $this->pushNotificationId = $pushNotificationId;
    }

    public function handle(FirebaseService $firebaseService): void
    {
        $pushNotification = PushNotification::find($this->pushNotificationId);

        if (!$pushNotification) {
            Log::warning("SendCustomPushJob: Push notification ID {$this->pushNotificationId} не найден");
            return;
        }

        // Проверяем статус - должен быть scheduled
        if ($pushNotification->status !== PushNotification::STATUS_SCHEDULED) {
            Log::info("SendCustomPushJob: Push notification ID {$this->pushNotificationId} имеет статус {$pushNotification->status}, пропускаем");
            return;
        }

        // Проверяем время отправки
        if ($pushNotification->scheduled_at && Carbon::now()->lt($pushNotification->scheduled_at)) {
            Log::info("SendCustomPushJob: Push notification ID {$this->pushNotificationId} запланирован на позже");
            return;
        }

        // Меняем статус на "отправляется"
        $pushNotification->update(['status' => PushNotification::STATUS_SENDING]);

        Log::info("SendCustomPushJob: Начинаем отправку push notification ID {$this->pushNotificationId}");

        try {
            // Получаем пользователей по таргетингу
            $users = $pushNotification->getTargetUsers()->get();

            $sentCount = 0;
            $failedCount = 0;

            foreach ($users as $user) {
                // Получаем АКТИВНЫЙ токен пользователя (только если авторизован)
                $activeToken = DeviceToken::getActiveTokenForUser($user->id);
                
                if (empty($activeToken)) {
                    continue; // Пропускаем если пользователь не авторизован на устройстве
                }

                try {
                    // Получаем количество непрочитанных уведомлений для badge
                    $unreadCount = $user->notifications()
                        ->where('is_read', false)
                        ->count();

                    // Создаём уведомление в БД
                    Notification::create([
                        'user_id' => $user->id,
                        'title' => $pushNotification->title,
                        'body' => $pushNotification->body,
                        'is_read' => false,
                        'label' => 'custom_push',
                        'source_id' => $pushNotification->id,
                    ]);

                    // Отправляем push через Firebase
                    $success = $firebaseService->sendPushNotification(
                        $pushNotification->id,
                        $unreadCount + 1,
                        'custom_push',
                        $activeToken, // Используем активный токен
                        $pushNotification->title,
                        $pushNotification->body,
                        [
                            'type' => 'custom_push',
                            'push_id' => (string) $pushNotification->id,
                        ]
                    );

                    if ($success) {
                        $sentCount++;
                    } else {
                        $failedCount++;
                    }
                } catch (\Exception $e) {
                    Log::warning("SendCustomPushJob: Ошибка отправки пользователю {$user->id}", [
                        'error' => $e->getMessage(),
                    ]);
                    $failedCount++;
                }

                // Небольшая задержка, чтобы не перегружать FCM
                usleep(50000); // 50ms
            }

            // Обновляем статистику
            $pushNotification->update([
                'status' => PushNotification::STATUS_SENT,
                'sent_at' => Carbon::now(),
                'sent_count' => $sentCount,
                'failed_count' => $failedCount,
                'recipients_count' => $users->count(),
            ]);

            Log::info("SendCustomPushJob: Push notification ID {$this->pushNotificationId} отправлен", [
                'total' => $users->count(),
                'sent' => $sentCount,
                'failed' => $failedCount,
            ]);

        } catch (\Exception $e) {
            Log::error("SendCustomPushJob: Критическая ошибка при отправке push notification ID {$this->pushNotificationId}", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            $pushNotification->update([
                'status' => PushNotification::STATUS_FAILED,
                'error_message' => $e->getMessage(),
            ]);

            throw $e; // Для повторных попыток
        }
    }

    /**
     * Обработка неудачного выполнения задания
     */
    public function failed(\Throwable $exception): void
    {
        $pushNotification = PushNotification::find($this->pushNotificationId);
        
        if ($pushNotification) {
            $pushNotification->update([
                'status' => PushNotification::STATUS_FAILED,
                'error_message' => $exception->getMessage(),
            ]);
        }

        Log::error("SendCustomPushJob: Задание для push notification ID {$this->pushNotificationId} полностью провалено", [
            'error' => $exception->getMessage(),
        ]);
    }
}

