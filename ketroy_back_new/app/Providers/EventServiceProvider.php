<?php

namespace App\Providers;

use App\Events\BonusUpdated;
use App\Events\GiftCertificateCreated;
use App\Events\NewsPublished;
use App\Events\UserInteractionEvent;
use App\Listeners\LogUserInteraction;
use App\Listeners\SendBonusNotification;
use App\Listeners\SendGiftCertificateNotification;
use App\Listeners\SendNewsNotification;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;
use App\Events\NotificationSendedEvent;
use App\Listeners\CreateNotification;


class EventServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        //
    }

    protected $listen = [
        UserInteractionEvent::class => [
            LogUserInteraction::class,
        ],
        BonusUpdated::class => [
            SendBonusNotification::class
        ],
        GiftCertificateCreated::class => [
            SendGiftCertificateNotification::class
        ],
        NewsPublished::class => [
            SendNewsNotification::class
        ],
        NotificationSendedEvent::class => [
            CreateNotification::class
        ]

    ];


    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        //
    }
}
