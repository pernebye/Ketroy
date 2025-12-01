<?php

namespace App\Http\Controllers;

use App\Events\UserRegistered;
use App\Models\DeviceToken;
use App\Models\PromoCode;
use App\Models\User;
use App\Services\SmsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Carbon\Carbon;
use App\Services\S3Service;
use App\Services\OneCApiService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class AuthController extends Controller
{
    protected SmsService $smsService;
    protected S3Service $s3Service;
    protected OneCApiService $oneCApi;

    public function __construct(SmsService $smsService, S3Service $s3Service, OneCApiService $oneCApi)
    {
        $this->smsService = $smsService;
        $this->s3Service = $s3Service;
        $this->oneCApi = $oneCApi;
    }

    /**
     * @OA\Post(
     *     path="/register",
     *     summary="Регистрация нового пользователя",
     *     description="Создание новой учетной записи пользователя. Требуется предварительная верификация телефона через /verify-code",
     *     tags={"Auth"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"name", "surname", "phone", "country_code"},
     *             @OA\Property(property="name", type="string", example="Иван"),
     *             @OA\Property(property="device_token", type="string", example="740f4707 bebcf74f 9b7c25d4 8e335894 5f6aa01d a5ddb387 462c7eaf 61bb78ad"),
     *             @OA\Property(property="surname", type="string", example="Иванов"),
     *             @OA\Property(property="phone", type="string", example="79001234567"),
     *             @OA\Property(property="country_code", type="string", example="+7")
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Пользователь успешно зарегистрирован",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="User registered successfully!"),
     *             @OA\Property(property="user", type="object")
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Телефон не верифицирован"
     *     ),
     *     @OA\Response(
     *         response=409,
     *         description="Пользователь уже зарегистрирован"
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Ошибка валидации"
     *     )
     * )
     */
    public function register(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'surname' => 'required|string|max:255',
            'phone' => 'required|string|regex:/^\d{10}$/',
            'country_code' => 'required|string|regex:/^\+\d{1,3}$/',
            'device_token' => 'nullable|string|max:255',
            'birthdate' => 'required|date',
            'city' => 'required|string',
            'height' => 'required|in:4,6,8',
            'clothing_size' => 'required|in:46,48,50,52,54,56,58,60,62,64',
            'shoe_size' => 'required|in:39,40,41,42,43,44,45,46'
        ]);

        // ВАЖНО: Проверяем, что телефон был верифицирован через SMS
        $isVerified = Cache::get("phone_verified_{$request->phone}");
        if (!$isVerified) {
            Log::warning('Registration attempt without phone verification', [
                'phone' => $request->phone,
                'ip' => $request->ip(),
            ]);
            return response()->json([
                'message' => 'Телефон не верифицирован. Сначала подтвердите номер через SMS код.',
                'error_code' => 'PHONE_NOT_VERIFIED'
            ], 400);
        }

        // Проверяем, не зарегистрирован ли уже пользователь
        $user = User::where('phone', $request->phone)->first();

        if ($user) {
            // 409 Conflict - более правильный статус код для "уже существует"
            return response()->json([
                'message' => 'Пользователь с этим номером уже зарегистрирован.',
                'error_code' => 'USER_ALREADY_EXISTS'
            ], 409);
        }

        // Создаём пользователя
        $userData = $request->only([
            'name',
            'surname',
            'country_code',
            'phone',
            'device_token',
            'birthdate',
            'city',
            'height',
            'clothing_size',
            'shoe_size'
        ]);
        $userData['bonus_amount'] = 0;
        $userData['discount'] = 0;
        $userData['used_promo_code'] = false;

        $user = User::create($userData);

        // Синхронизация с 1С (асинхронно, не блокируем регистрацию)
        try {
            $this->oneCApi->findOrCreateClient([
                'fio' => $request->surname . ' ' . $request->name,
                'phone' => str_replace('+7', '8', $request->country_code) . $request->phone,
                'birthDate' => date("Y-m-d", strtotime($request->birthdate)) . 'T00:00:00'
            ]);
        } catch (\Exception $e) {
            // Логируем ошибку, но не блокируем регистрацию
            Log::error('1C sync failed during registration', [
                'user_id' => $user->id,
                'phone' => $request->phone,
                'error' => $e->getMessage(),
            ]);
        }

        // Очищаем флаг верификации после успешной регистрации
        Cache::forget("phone_verified_{$request->phone}");

        // Активируем device token для пользователя (если передан)
        if (!empty($request->device_token)) {
            DeviceToken::activateForUser(
                $user->id,
                $request->device_token,
                $request->device_type ?? null,
                $request->device_info ?? null
            );
        }

        $token = $user->createToken('authToken')->plainTextToken;

        Log::info('User registered successfully', [
            'user_id' => $user->id,
            'phone' => $request->phone,
        ]);

        return response()->json([
            'token' => $token,
            'user' => $user,
            'message' => 'Успешно зарегистрировано.'
        ], 201);
    }

    /**
     * @OA\Post(
     *     path="/send-verification-code",
     *     summary="Отправка кода подтверждения для регистрации",
     *     description="Отправляет код подтверждения на указанный номер телефона. Возвращает user_exists: true если пользователь уже зарегистрирован.",
     *     tags={"Auth"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"phone", "country_code"},
     *             @OA\Property(property="phone", type="string", example="79001234567"),
     *             @OA\Property(property="country_code", type="string", example="+7")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Код подтверждения отправлен",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Код подтверждения отправлен."),
     *             @OA\Property(property="user_exists", type="boolean", example=false)
     *         )
     *     )
     * )
     */
    public function sendVerificationCode(Request $request): JsonResponse
    {
        try {
        $request->validate([
            'phone' => 'required|string|regex:/^\d{10}$/',
            'country_code' => 'required|string|regex:/^\+\d{1,3}$/',
        ]);

            $verificationCode = (string) rand(10000, 99999);
        $message = 'Ketroy. Ваш код верификации: ' . $verificationCode;

        $user = User::where('phone', $request->phone)->first();

        if ($user) {
            // Пользователь уже существует - отправляем код для входа
            $user->verification_code = $verificationCode;
            $user->save();

            if (config('services.mobizon.api_key')) {
                $this->smsService->send($request->country_code . $request->phone, $message);
            } else {
                Log::info("Development mode: Verification code for existing user {$request->phone} is {$verificationCode}");
            }

            return response()->json([
                'message' => 'Код подтверждения отправлен.',
                'user_exists' => true
            ], 200);
        }

        // Новый пользователь - отправляем код верификации
        Cache::put("verification_{$request->phone}", $verificationCode, now()->addMinutes(10));

        if (config('services.mobizon.api_key')) {
            $this->smsService->send($request->country_code . $request->phone, $message);
        } else {
            Log::info("Development mode: Verification code for {$request->phone} is {$verificationCode}");
        }

        return response()->json([
            'message' => 'Код подтверждения отправлен.',
            'user_exists' => false
        ], 200);
        } catch (\Exception $e) {
            Log::error('sendVerificationCode error', [
                'phone' => $request->phone ?? 'unknown',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            
            return response()->json([
                'message' => 'Ошибка при отправке кода: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * @OA\Post(
     *     path="/login-send-code",
     *     summary="Отправка кода подтверждения для входа",
     *     description="Отправляет код подтверждения только для существующих пользователей. Возвращает user_exists: false если пользователь не найден.",
     *     tags={"Auth"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"phone", "country_code"},
     *             @OA\Property(property="phone", type="string", example="79001234567"),
     *             @OA\Property(property="country_code", type="string", example="+7")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Код подтверждения отправлен или пользователь не найден",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Код подтверждения отправлен."),
     *             @OA\Property(property="user_exists", type="boolean", example=true)
     *         )
     *     )
     * )
     */
    public function loginSendCode(Request $request): JsonResponse
    {
        try {
        $request->validate([
            'phone' => 'required|string|regex:/^\d{10}$/',
            'country_code' => 'required|string|regex:/^\+\d{1,3}$/',
        ]);

        $user = User::where('phone', $request->phone)->first();

        if (!$user) {
            // Пользователь не найден - возвращаем флаг для перенаправления на регистрацию
            return response()->json([
                'message' => 'Пользователь не найден.',
                'user_exists' => false
            ], 200);
        }

        // Пользователь существует - отправляем код для входа
            $verificationCode = (string) rand(10000, 99999);
        $message = 'Ketroy. Ваш код верификации: ' . $verificationCode;

        $user->verification_code = $verificationCode;
        $user->save();

        if (config('services.mobizon.api_key')) {
            $this->smsService->send($request->country_code . $request->phone, $message);
        } else {
            Log::info("Development mode: Login verification code for {$request->phone} is {$verificationCode}");
        }

        return response()->json([
            'message' => 'Код подтверждения отправлен.',
            'user_exists' => true
        ], 200);
        } catch (\Exception $e) {
            Log::error('loginSendCode error', [
                'phone' => $request->phone ?? 'unknown',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            
            return response()->json([
                'message' => 'Ошибка при отправке кода: ' . $e->getMessage(),
            ], 500);
        }
    }


    /**
     * @OA\Post(
     *     path="/verify-code",
     *     summary="Подтверждение кода для авторизации",
     *     description="Проверка кода подтверждения и авторизация пользователя",
     *     tags={"Auth"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *      *       required={"phone", "verification_code"},
     *             @OA\Property(property="phone", type="string", example="79001234567"),
     *             @OA\Property(property="verification_code", type="string", example="12345")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Авторизация успешна",
     *         @OA\JsonContent(
     *             @OA\Property(property="token", type="string", example="your-auth-token")
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Код истек или неверный"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Пользователь не найден"
     *     )
     * )
     */
    public function verifyCode(Request $request): JsonResponse
    {
        $request->validate([
            'phone' => 'required|string|regex:/^\d{10}$/',
            'verification_code' => 'required|string|min:5|max:5',
        ]);

        $user = User::where('phone', $request->phone)->first();
        if ($user) {
            $cachedCode = $user->verification_code;
        } else {
            $cachedCode = Cache::get("verification_{$request->phone}");
        }

        if (!$cachedCode || $request->verification_code != $cachedCode) {
            Log::warning('Invalid verification code attempt', [
                'phone' => $request->phone,
                'ip' => $request->ip(),
            ]);
            return response()->json(['message' => 'Неверный код.'], 400);
        }

        Cache::forget("verification_{$request->phone}");

        if ($user) {
            // Существующий пользователь - вход
            $token = $user->createToken('authToken')->plainTextToken;
            $user->verification_code = "";
            $user->save();
            
            Log::info('User logged in via SMS', ['user_id' => $user->id]);
            
            return response()->json([
                'token' => $token,
                'user' => $user,
                'message' => 'Код подтвержден.',
                'is_new_user' => false
            ], 200);
        }

        // Новый пользователь - устанавливаем флаг верификации для последующей регистрации
        // Флаг действителен 15 минут
        Cache::put("phone_verified_{$request->phone}", true, now()->addMinutes(15));
        
        Log::info('Phone verified for new registration', ['phone' => $request->phone]);

        return response()->json([
            'message' => 'Код подтвержден. Теперь вы можете завершить регистрацию.',
            'is_new_user' => true
        ], 200);
    }


    /**
     * @OA\Post(
     *     path="/logout",
     *     summary="Выход пользователя",
     *     description="Удаление токена авторизации пользователя и деактивация push-уведомлений",
     *     tags={"Auth"},
     *     security={{"sanctum": {}}},
     *     @OA\RequestBody(
     *         required=false,
     *         @OA\JsonContent(
     *             @OA\Property(property="device_token", type="string", description="FCM токен устройства для деактивации")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Выход успешен",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Logged out successfully!")
     *         )
     *     )
     * )
     */
    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();
        
        // Деактивируем device token (если передан - только его, иначе все)
        $deviceToken = $request->device_token;
        DeviceToken::deactivateForUser($user->id, $deviceToken);
        
        // Удаляем auth токены
        $user->tokens()->delete();

        Log::info('User logged out', [
            'user_id' => $user->id,
            'device_token_deactivated' => !empty($deviceToken),
        ]);

        return response()->json(['message' => 'Logged out successfully!']);
    }
    
    /**
     * @OA\Post(
     *     path="/activate-device",
     *     summary="Активация устройства для push-уведомлений",
     *     description="Активирует device token для текущего пользователя. Деактивирует этот токен для других пользователей.",
     *     tags={"Auth"},
     *     security={{"sanctum": {}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"device_token"},
     *             @OA\Property(property="device_token", type="string", description="FCM токен устройства"),
     *             @OA\Property(property="device_type", type="string", description="Тип устройства (ios, android, web)"),
     *             @OA\Property(property="device_info", type="string", description="Информация об устройстве")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Устройство активировано",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Device activated successfully"),
     *             @OA\Property(property="is_active", type="boolean", example=true)
     *         )
     *     )
     * )
     */
    public function activateDevice(Request $request): JsonResponse
    {
        $request->validate([
            'device_token' => 'required|string|min:100',
            'device_type' => 'nullable|string|in:ios,android,web',
            'device_info' => 'nullable|string|max:255',
        ]);

        $user = $request->user();
        
        DeviceToken::activateForUser(
            $user->id,
            $request->device_token,
            $request->device_type,
            $request->device_info
        );

        // Также обновляем legacy поле device_token для обратной совместимости
        $user->device_token = $request->device_token;
        $user->save();

        return response()->json([
            'message' => 'Device activated successfully',
            'is_active' => true,
        ]);
    }
    
    /**
     * @OA\Post(
     *     path="/deactivate-device",
     *     summary="Деактивация устройства для push-уведомлений",
     *     description="Деактивирует push-уведомления для текущего устройства без выхода из аккаунта",
     *     tags={"Auth"},
     *     security={{"sanctum": {}}},
     *     @OA\RequestBody(
     *         required=false,
     *         @OA\JsonContent(
     *             @OA\Property(property="device_token", type="string", description="FCM токен устройства (если не передан - деактивируются все)")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Устройство деактивировано",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Device deactivated successfully"),
     *             @OA\Property(property="is_active", type="boolean", example=false)
     *         )
     *     )
     * )
     */
    public function deactivateDevice(Request $request): JsonResponse
    {
        $user = $request->user();
        
        DeviceToken::deactivateForUser($user->id, $request->device_token);

        // Также очищаем legacy поле
        if (empty($request->device_token) || $user->device_token === $request->device_token) {
            $user->device_token = null;
            $user->save();
        }

        return response()->json([
            'message' => 'Device deactivated successfully',
            'is_active' => false,
        ]);
    }

    /**
     * @OA\Get(
     *     path="/user",
     *     summary="Получение информации о текущем пользователе",
     *     description="Возвращает информацию о текущем пользователе, который авторизован",
     *     tags={"Auth"},
     *     security={{"sanctum": {}}},
     *     @OA\Response(
     *         response=200,
     *         description="Информация о пользователе",
     *         @OA\JsonContent(
     *             @OA\Property(property="name", type="string", example="Иван"),
     *             @OA\Property(property="surname", type="string", example="Иванов"),
     *             @OA\Property(property="phone", type="string", example="79001234567"),
     *             @OA\Property(property="country_code", type="string", example="+7")
     *         )
     *     )
     * )
     */
    public function user(Request $request): JsonResponse
    {
        $user = $request->user();
        
        // Получаем актуальные данные о бонусах из 1С (единственный источник правды)
        $phone1C = str_replace('+7', '8', $user->country_code) . $user->phone;
        $oneCData = $this->oneCApi->getClientInfo($phone1C);
        
        // Формируем ответ с данными пользователя
        $userData = $user->load('promoCode')->toArray();
        
        // Перезаписываем бонусы из 1С (если получены)
        if ($oneCData) {
            $userData['bonus_amount'] = $oneCData['bonusAmount'] ?? 0;
            $userData['discount'] = $oneCData['personalDiscount'] ?? $user->discount ?? 0;
        }

        return response()->json([
            'user' => $userData
        ]);
    }

    public function deleteUser(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->gifts()->delete();
        $user->giftCertificates()->delete();
        $user->promoCode()->delete();
        $request->user()->tokens()->delete();
        $user->delete();

        return response()->json(['message' => 'Пользователь удален.'], 200);
    }
}
