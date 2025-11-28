<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use App\Models\DeviceToken;
use App\Models\News;
use App\Models\User;
use App\Services\FirebaseService;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendNewsPushJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected int $newsId;

    /**
     * Количество попыток выполнения задания
     */
    public int $tries = 3;

    /**
     * Время ожидания между попытками (секунды)
     */
    public int $backoff = 60;

    public function __construct(int $newsId)
    {
        $this->newsId = $newsId;
    }

    public function handle(FirebaseService $firebaseService)
    {
        $news = News::with('blocks')->find($this->newsId);

        if (!$news) {
            Log::warning("SendNewsPushJob: Новость с ID {$this->newsId} не найдена");
            return;
        }

        // Проверяем, не было ли уже отправлено уведомление
        if ($news->notification_sent) {
            Log::info("SendNewsPushJob: Уведомление для новости ID {$this->newsId} уже было отправлено");
            return;
        }

        // Получаем города из новости (массив)
        $newsCities = $news->city ?? [];
        $newsShoeSize = $news->shoe_size;
        $newsClothingSize = $news->clothing_size;

        // Строим запрос для фильтрации пользователей
        // Используем новую систему device_tokens с проверкой is_active
        $usersQuery = User::query()
            ->whereHas('deviceTokens', function ($query) {
                $query->where('is_active', true);
            });

        // Фильтрация по городу
        // Если в новости выбрано "Все" - отправляем всем
        // Если выбраны конкретные города - фильтруем по ним
        if (!empty($newsCities) && !in_array('Все', $newsCities)) {
            $usersQuery->where(function ($query) use ($newsCities) {
                $query->whereIn('city', $newsCities)
                      ->orWhereNull('city')
                      ->orWhere('city', '');
            });
        }

        // Фильтрация по размеру обуви
        // Если "Все" или пусто - отправляем всем
        // Если конкретный размер - отправляем ТОЛЬКО пользователям с этим размером
        if (!empty($newsShoeSize) && $newsShoeSize !== 'Все') {
            $usersQuery->where('shoe_size', $newsShoeSize);
        }

        // Фильтрация по размеру одежды
        // Если "Все" или пусто - отправляем всем
        // Если конкретный размер - отправляем ТОЛЬКО пользователям с этим размером
        if (!empty($newsClothingSize) && $newsClothingSize !== 'Все') {
            $usersQuery->where('clothing_size', $newsClothingSize);
        }

        $users = $usersQuery->get();

        if ($users->isEmpty()) {
            Log::info("SendNewsPushJob: Нет пользователей для отправки уведомления о новости ID {$this->newsId}");
            $news->update(['notification_sent' => true]);
            return;
        }

        // Формируем текст уведомления
        $title = $news->name;
        
        // Берём первый текстовый блок как описание
        $description = '';
        if ($news->blocks->isNotEmpty()) {
            $firstTextBlock = $news->blocks->first(function ($block) {
                return !empty($block->text);
            });
            if ($firstTextBlock) {
                // Обрезаем до 100 символов
                $description = mb_strlen($firstTextBlock->text) > 100 
                    ? mb_substr($firstTextBlock->text, 0, 100) . '...'
                    : $firstTextBlock->text;
            }
        }

        // Если описание пустое, используем стандартный текст
        if (empty($description)) {
            $description = 'Новая новость доступна в приложении';
        }

        $successCount = 0;
        $failCount = 0;

        Log::info("SendNewsPushJob: Начинаем отправку уведомлений для новости ID {$this->newsId}", [
            'users_count' => $users->count(),
            'cities' => $newsCities,
            'shoe_size' => $newsShoeSize,
            'clothing_size' => $newsClothingSize,
        ]);

        foreach ($users as $user) {
            try {
                // Получаем активный токен пользователя
                $activeToken = DeviceToken::getActiveTokenForUser($user->id);
                
                if (empty($activeToken)) {
                    continue; // Пропускаем если нет активного токена
                }
                
                $notifications = $user->notifications()->where('is_read', false)->count();
                $badge = $notifications + 1;

                $result = $firebaseService->sendPushNotification(
                    $this->newsId,
                    $badge,
                    'news',
                    $activeToken, // Используем активный токен
                    $title,
                    $description,
                    ['type' => 'news', 'news_id' => (string)$this->newsId]
                );

                if ($result) {
                    $successCount++;
                } else {
                    $failCount++;
                }
            } catch (\Exception $e) {
                $failCount++;
                Log::error("SendNewsPushJob: Ошибка отправки уведомления пользователю {$user->id}", [
                    'error' => $e->getMessage()
                ]);
            }
        }

        // Отмечаем, что уведомление отправлено
        $news->update(['notification_sent' => true]);

        Log::info("SendNewsPushJob: Завершена отправка уведомлений для новости ID {$this->newsId}", [
            'success' => $successCount,
            'failed' => $failCount,
            'total' => $users->count(),
        ]);
    }

    /**
     * Обработка неудачного выполнения задания
     */
    public function failed(\Throwable $exception): void
    {
        Log::error("SendNewsPushJob: Критическая ошибка при отправке уведомлений для новости ID {$this->newsId}", [
            'error' => $exception->getMessage(),
            'trace' => $exception->getTraceAsString(),
        ]);
    }
}
