<?php

namespace App\Observers;

use App\Jobs\SendBonusPushJob;
use App\Models\User;
use App\Models\PromoCode;
use App\Services\ChottuLinkService;
use App\Services\OneCApiService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

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
     */
    public function updated(User $user): void
    {
        if ($user->wasChanged('bonus_amount')) {
            $diff = $user->bonus_amount - $user->getOriginal('bonus_amount');
            
            // Получаем withDelay из кэша (устанавливается в TransactionController)
            $withDelay = Cache::pull('bonus_with_delay_' . $user->id, false);
            
            Log::info('[UserObserver] bonus_amount changed', [
                'user_id' => $user->id,
                'old' => $user->getOriginal('bonus_amount'),
                'new' => $user->bonus_amount,
                'diff' => $diff,
                'withDelay' => $withDelay,
            ]);

            if ($diff > 0) {
                // Начисление бонусов
                SendBonusPushJob::dispatch($diff, $user->id, 'add', $withDelay);
            } elseif ($diff < 0) {
                // Списание бонусов
                SendBonusPushJob::dispatch(abs($diff), $user->id, 'write-off', false);
            }
        }
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
