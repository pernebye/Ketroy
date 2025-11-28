<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class UserInteractionEvent
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $eventType;
    public $eventData;
    public $user;

    /**
     * Create a new event instance.
     */
    public function __construct($eventType, $eventData, $user = null)
    {
        $this->eventType = $eventType;
        $this->eventData = $eventData;
        $this->user = $user;
    }


    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('channel-name'),
        ];
    }
}
