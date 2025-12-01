<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | Конфигурация внешних сервисов для Ketroy.
    |
    */

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'resend' => [
        'key' => env('RESEND_KEY'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Firebase Cloud Messaging
    |--------------------------------------------------------------------------
    */
    'fcm' => [
        'project_id' => env('FIREBASE_PROJECT_ID'),
    ],

    /*
    |--------------------------------------------------------------------------
    | ChottuLink (Deep Links)
    |--------------------------------------------------------------------------
    */
    'chottulink' => [
        'base_url' => 'https://api2.chottulink.com',
        'api_key' => env('CHOTTULINK_API_KEY'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Mobizon SMS Service
    |--------------------------------------------------------------------------
    */
    'mobizon' => [
        'api_key' => env('MOBIZON_API_KEY'),
        'api_server' => env('MOBIZON_API_SERVER', 'api.mobizon.kz'),
    ],

    /*
    |--------------------------------------------------------------------------
    | 1C ERP Integration
    |--------------------------------------------------------------------------
    */
    'one_c' => [
        'base_url' => env('ONE_C_BASE_URL'),
        'username' => env('ONE_C_USERNAME'),
        'password' => env('ONE_C_PASSWORD'),
        'token' => env('API_1C_TOKEN') ?? env('ONE_C_TOKEN'), // API_1C_TOKEN используется в middleware
        'timeout' => env('ONE_C_TIMEOUT', 30),
        'retry_times' => env('ONE_C_RETRY_TIMES', 3),
        'retry_sleep' => env('ONE_C_RETRY_SLEEP', 1000), // миллисекунды
        'webhook_secret' => env('API_1C_TOKEN') ?? env('ONE_C_WEBHOOK_SECRET') ?? env('ONE_C_TOKEN'), // Секрет для проверки webhook-ов от 1С
    ],

];
