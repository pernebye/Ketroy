<?php

namespace App\Events;

use Illuminate\Foundation\Events\Dispatchable;

class BonusUpdated
{
    use Dispatchable;

    public $device_token;
    public $amount;

    public function __construct($device_token, $amount)
    {
        $this->device_token = $device_token;
        $this->amount = $amount;
    }
}
