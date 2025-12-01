<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

/**
 * Middleware для проверки подписи запросов от 1С
 * 
 * Проверяет заголовок X-1C-Secret для аутентификации webhook-ов.
 */
class Verify1CSignature
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $secret = $request->header('X-1C-Secret');
        $expectedSecret = config('services.one_c.webhook_secret');

        // Если секрет не настроен - пропускаем проверку (для разработки)
        if (empty($expectedSecret)) {
            Log::warning('[1C Middleware] Webhook secret not configured, skipping verification');
            return $next($request);
        }

        if (empty($secret)) {
            Log::warning('[1C Middleware] Missing X-1C-Secret header', [
                'ip' => $request->ip(),
                'url' => $request->fullUrl(),
            ]);
            return response()->json([
                'status' => 'error',
                'message' => 'Missing authentication header',
            ], 401);
        }

        if (!hash_equals($expectedSecret, $secret)) {
            Log::warning('[1C Middleware] Invalid X-1C-Secret', [
                'ip' => $request->ip(),
                'url' => $request->fullUrl(),
            ]);
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid authentication',
            ], 401);
        }

        return $next($request);
    }
}




