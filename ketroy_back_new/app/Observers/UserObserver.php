<?php

namespace App\Observers;

use App\Models\User;
use App\Models\PromoCode;
use App\Services\OneCApiService;

class UserObserver
{
    /**
     * Handle the User "created" event.
     */
    public function created(User $user): void
    {
        PromoCode::create([
            'user_id' => $user->id,
            'code' => strtoupper(bin2hex(random_bytes(4))), // Генерация уникального кода
        ]);

        $oneCApiService = new OneCApiService();
        if ($user->discount < 10) {
            $oneCApiService->updateDiscount(str_replace('+7', '8', $user->country_code) . $user->phone, 10);
            $user->discount = 10;
            $user->save();
        }
    }

    /**
     * Handle the User "updated" event.
     * 
     * ВАЖНО: Push-уведомления о бонусах теперь отправляются напрямую из TransactionController,
     * а не через отслеживание изменения bonus_amount.
     * Поле bonus_amount в БД больше не является источником правды — 1С единственный источник.
     */
    public function updated(User $user): void
    {
        // Логика отправки push-уведомлений о бонусах перенесена в TransactionController
        // для устранения дублирования и корректной работы с параметром withDelay
    }

    /**
     * Handle the User "deleted" event.
     */
    public function deleted(User $user): void
    {
        //
    }

    /**
     * Handle the User "restored" event.
     */
    public function restored(User $user): void
    {
        //
    }

    /**
     * Handle the User "force deleted" event.
     */
    public function forceDeleted(User $user): void
    {
        //
    }
}
