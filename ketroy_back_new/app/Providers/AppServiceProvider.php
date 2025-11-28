<?php

namespace App\Providers;

use App\Models\Gift;
use Illuminate\Support\ServiceProvider;
use App\Models\User;
use App\Models\News;
use App\Observers\GiftObserver;
use App\Observers\UserObserver;
use App\Observers\NewsObserver;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        User::observe(UserObserver::class);
        Gift::observe(GiftObserver::class);
        News::observe(NewsObserver::class);
    }
}
