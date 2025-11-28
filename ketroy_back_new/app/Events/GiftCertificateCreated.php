<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class GiftCertificateCreated
{
    use Dispatchable, SerializesModels;

    public $deviceToken;
    public $amount;

    public function __construct(string $deviceToken, array $amount)
    {
        $this->deviceToken = $deviceToken;
        $this->amount = $amount;
    }
}
