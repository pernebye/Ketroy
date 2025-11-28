<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class Verify1CToken
{
    public function handle(Request $request, Closure $next): Response
    {
        // Проверяем оба возможных заголовка (X-1C-TOKEN и X-1C-Secret)
        $token = $request->header('X-1C-TOKEN') ?? $request->header('X-1C-Secret');

        if (!$token || $token !== env('API_1C_TOKEN')) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        return $next($request);
    }
}
