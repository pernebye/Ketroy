<?php

namespace App\Listeners;

use App\Events\UserInteractionEvent;
use App\Models\AnalyticsEvent;
use Illuminate\Support\Facades\Log;


class LogUserInteraction
{
    /**
     * Create the event listener.
     */
    public function __construct()
    {
        //
    }

    /**
     * Handle the event.
     */
    public function handle(UserInteractionEvent $event)
    {
        AnalyticsEvent::create([
            'event_type' => $event->eventType,
            'event_data' => $event->eventData,
            'user_id' => $event->user ? $event->user->id : null,
        ]);
    }
}
