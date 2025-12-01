<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class Verify1CToken
{
    public function handle(Request $request, Closure $next): Response
    {
        // Проверяем все возможные заголовки для токена
        $token = $request->header('X-1C-TOKEN') 
            ?? $request->header('X-1C-Secret')
            ?? ($request->bearerToken()); // Bearer token из Authorization заголовка
        
        // Используем config вместо env для работы с кэшированным конфигом
        // Проверяем сначала webhook_secret, потом token
        $expectedToken = config('services.one_c.webhook_secret') ?? config('services.one_c.token');
        
        // Логируем для отладки
        Log::info('[1C Token Middleware]', [
            'has_token' => !empty($token),
            'token_received' => $token ? substr($token, 0, 10) . '...' : 'none',
            'token_expected' => $expectedToken ? substr($expectedToken, 0, 10) . '...' : 'none',
            'headers' => [
                'X-1C-TOKEN' => $request->header('X-1C-TOKEN') ? 'present' : 'missing',
                'X-1C-Secret' => $request->header('X-1C-Secret') ? 'present' : 'missing',
                'Authorization' => $request->header('Authorization') ? 'present' : 'missing',
            ],
            'all_headers' => $request->headers->all(),
        ]);

        if (!$token || $token !== $expectedToken) {
            Log::warning('[1C Token Middleware] Unauthorized', [
                'token_matches' => $token === $expectedToken,
                'has_token' => !empty($token),
                'token_received_length' => $token ? strlen($token) : 0,
                'token_expected_length' => $expectedToken ? strlen($expectedToken) : 0,
            ]);
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        Log::info('[1C Token Middleware] Token validated successfully');
        return $next($request);
    }
}
