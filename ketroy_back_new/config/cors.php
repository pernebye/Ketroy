<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Настройки CORS для Ketroy API.
    | В development разрешаем localhost, в production - только наши домены.
    |
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],

    // Разрешённые origins берём из .env
    // В development режиме разрешаем все origins для мобильных приложений
    'allowed_origins' => env('APP_ENV') === 'local' 
        ? ['*'] 
        : array_filter(
            explode(',', env('CORS_ALLOWED_ORIGINS', 'http://localhost:3000,http://localhost:8080'))
        ),

    'allowed_origins_patterns' => [],

    'allowed_headers' => [
        'Content-Type',
        'Authorization',
        'X-Requested-With',
        'Accept',
        'Origin',
        'X-CSRF-TOKEN',
    ],

    'exposed_headers' => [],

    'max_age' => 86400, // 24 часа кэширования preflight запросов

    // Важно: supports_credentials должен быть false при использовании '*' в allowed_origins
    'supports_credentials' => env('APP_ENV') !== 'local',

];
