<?php

use App\Http\Middleware\Verify1CToken;
use App\Http\Middleware\Verify1CSignature;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Spatie\Permission\Middleware\RoleMiddleware;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__ . '/../routes/web.php',
        api: __DIR__ . '/../routes/api.php',
        commands: __DIR__ . '/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->alias([
            'role' => RoleMiddleware::class,
            '1c.token' => Verify1CToken::class,
            'verify.1c.signature' => Verify1CSignature::class,
        ]);

        // API Rate Limiting
        $middleware->api(prepend: [
            \Illuminate\Routing\Middleware\ThrottleRequests::class . ':api',
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })
    ->withSchedule(function (Schedule $schedule) {
        $schedule->command('notify:birthday')->hourly();
        $schedule->command('analytics:analyze-promotions')->daily();
        $schedule->command('gifts:date-based')->dailyAt('05:00');
        $schedule->command('gifts:accumulation')->everyFiveMinutes();
        $schedule->command('app:sync-clients-purchases')->everyTenMinutes();
        $schedule->command('push:process-scheduled')->everyMinute();
    })
    ->booting(function () {
        // Настройка Rate Limiting
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(
                (int) env('RATE_LIMIT_PER_MINUTE', 60)
            )->by($request->user()?->id ?: $request->ip());
        });

        // Более строгий лимит для верификации (защита от брутфорса)
        RateLimiter::for('verification', function (Request $request) {
            return Limit::perMinute(
                (int) env('RATE_LIMIT_VERIFICATION_PER_MINUTE', 5)
            )->by($request->ip());
        });

        // Лимит для авторизации
        RateLimiter::for('auth', function (Request $request) {
            return Limit::perMinute(10)->by($request->ip());
        });
    })
    ->create();
