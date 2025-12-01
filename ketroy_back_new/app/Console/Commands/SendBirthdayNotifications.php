<?php

namespace App\Console\Commands;

use App\Models\DeviceToken;
use App\Models\Promotion;
use App\Models\User;
use App\Models\Notification;
use Illuminate\Console\Command;
use Carbon\Carbon;
use App\Services\FirebaseService;
use Illuminate\Support\Facades\Log;

class SendBirthdayNotifications extends Command
{
    protected $signature = 'notify:birthday';

    protected $description = 'Отправить push-уведомления о дне рождения пользователям согласно настроенному расписанию';

    public function handle()
    {
        Log::info('[Birthday] Запущена команда отправки уведомлений о дне рождения');
        
        // Получаем активную акцию "День рождения"
        $birthdayPromotion = Promotion::where('type', 'birthday')
            ->where('is_archived', false)
            ->where('is_active', true)
            ->first();

        if (!$birthdayPromotion) {
            Log::info('[Birthday] Акция "День рождения" не найдена, не активна или архивирована');
            return;
        }

        // Получаем настройки из акции
        $settings = is_array($birthdayPromotion->settings) 
            ? $birthdayPromotion->settings 
            : json_decode($birthdayPromotion->settings, true);

        $notifications = $settings['birthday_notifications'] ?? [];

        if (empty($notifications)) {
            Log::info('[Birthday] Нет настроенных push-уведомлений в акции');
            return;
        }

        $currentHour = Carbon::now()->format('H');
        $sentCount = 0;

        foreach ($notifications as $notification) {
            // Проверяем, совпадает ли текущий час с часом отправки
            $sendTime = $notification['send_time'] ?? '10:00';
            $notificationHour = Carbon::createFromFormat('H:i', $sendTime)->format('H');
            
            if ($currentHour !== $notificationHour) {
                Log::debug("[Birthday] Пропуск уведомления: текущий час {$currentHour}, час отправки {$notificationHour}");
                continue;
            }

            $daysBefore = $notification['days_before'] ?? 2;
            $title = $notification['title'] ?? 'С днем рождения! 🎂';
            $body = $notification['body'] ?? 'Поздравляем с наступающим днем рождения!';

            // Вычисляем целевую дату
            $targetDate = Carbon::now()->addDays($daysBefore);

            // Находим пользователей с днём рождения в целевую дату
            // Теперь ищем пользователей с АКТИВНЫМ device token
            $users = User::whereMonth('birthdate', $targetDate->month)
                ->whereDay('birthdate', $targetDate->day)
                ->whereHas('deviceTokens', function ($query) {
                    $query->where('is_active', true);
                })
                ->get();

            if ($users->isEmpty()) {
                Log::info("[Birthday] Нет пользователей с ДР через {$daysBefore} дней ({$targetDate->format('d.m')})");
                continue;
            }

            Log::info("[Birthday] Найдено {$users->count()} пользователей с ДР через {$daysBefore} дней");

            foreach ($users as $user) {
                try {
                    // Получаем АКТИВНЫЙ токен пользователя
                    $activeToken = DeviceToken::getActiveTokenForUser($user->id);
                    
                    if (empty($activeToken)) {
                        continue; // Пропускаем если нет активного токена
                    }
                    
                    $firebase = new FirebaseService();
                    $notificationCount = $user->notifications()->where('is_read', false)->count();
                    $badge = $notificationCount + 1;
                    
                    // Отправляем push-уведомление с активным токеном
                    // FirebaseService автоматически создаст запись в БД через NotificationSendedEvent
                    $firebase->sendPushNotification(
                        null, 
                        $badge, 
                        'bonus',  // label = 'bonus' для навигации на страницу бонусов
                        $activeToken, 
                        $title, 
                        $body,
                        [
                            'type' => 'bonus',  // Бонусы начисляются за день рождения
                            'birthday' => 'true',
                        ]
                    );

                    $sentCount++;
                    Log::info("[Birthday] Push отправлен пользователю {$user->id} (ДР через {$daysBefore} дней)");
                } catch (\Exception $e) {
                    Log::error("[Birthday] Ошибка отправки push для пользователя {$user->id}: " . $e->getMessage());
                }
            }
        }
        
        Log::info("[Birthday] Завершено. Отправлено уведомлений: {$sentCount}");
    }
}
