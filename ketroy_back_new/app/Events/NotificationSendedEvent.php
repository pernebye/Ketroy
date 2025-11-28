<?php

namespace App\Events;

use App\Models\Notification;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class NotificationSendedEvent
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    /**
     * Create a new event instance.
     */

    public $userId;
    public $title;
    public $body;
    public $isRead;
    public $label;
    public ?int $sourceId;


    public function __construct(
        $userId,
        $title,
        $body,
        $isRead,
        $label,
        ?int $sourceId
    ) {
        $this->userId = $userId;
        $this->title = $title;
        $this->body = $body;
        $this->isRead = $isRead;
        $this->label = $label;
        $this->sourceId = $sourceId;
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
