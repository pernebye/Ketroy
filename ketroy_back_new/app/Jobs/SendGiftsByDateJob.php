<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use App\Services\GiftService;

class SendGiftsByDateJob implements ShouldQueue
{
    use Queueable;

    protected GiftService $giftService;


    /**
     * Create a new job instance.
     */
    public function __construct(GiftService $giftService)
    {
        $this->giftService = $giftService;
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        $this->giftService->checkAndAssignGiftByDatePromotions();
    }
}
