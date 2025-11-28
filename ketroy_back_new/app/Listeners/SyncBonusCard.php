<?php

namespace App\Listeners;

use App\Events\UserRegistered;
use App\Services\OneCSyncService;

class SyncBonusCard
{
    protected $oneCService;
    /**
     * Create the event listener.
     */

    public function __construct(OneCSyncService $service)
    {
        $this->oneCService = $service;
    }

    /**
     * Handle the event.
     */
    public function handle(UserRegistered $event)
    {
        $this->oneCService->syncGiftCertificate([
            'user_id' => $event->user->id,
            'card_number' => $event->user->bonus_card_number,
        ]);
    }
}
