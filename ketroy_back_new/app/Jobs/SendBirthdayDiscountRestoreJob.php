<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use App\Models\User;
use App\Services\OneCApiService;
use Illuminate\Support\Facades\Cache;


class SendBirthdayDiscountRestoreJob implements ShouldQueue
{
    use Queueable;

    /**
     * Create a new job instance.
     */
    protected $user;

    public function __construct(User $user)
    {
        $this->user = $user;
    }


    /**
     * Execute the job.
     */
    public function handle()
    {
        // Восстанавливаем старую скидку из кеша
        $oldDiscount = Cache::get("user_{$this->user->id}_old_discount");

        // Если старое значение найдено, восстанавливаем скидку
        if ($oldDiscount !== null) {
            $this->user->update(['discount' => $oldDiscount]);
            $oneCService = new OneCApiService();
            $oneCService->updateDiscount(str_replace('+7', '8', $this->user->country_code) . $this->user->phone, $oldDiscount);
            Cache::forget("user_{$this->user->id}_old_discount");
        }
    }
}
