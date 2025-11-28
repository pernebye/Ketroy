<?php

namespace App\Http\Controllers;

use App\Models\Admin;
use App\Models\DeviceToken;
use App\Models\Gift;
use App\Models\GiftCatalog;
use App\Models\User;
use App\Services\OneCApiService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;
use App\Services\S3Service;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class UserController extends Controller
{
    protected S3Service $s3Service;
    protected $oneCApi;

    public function __construct(S3Service $s3Service, OneCApiService $oneCApi)
    {
        $this->s3Service = $s3Service;
        $this->oneCApi = $oneCApi;
    }

    public function getUsers(Request $request): JsonResponse
    {
        $query = User::withCount('gifts');

        // Универсальный поиск по всем полям (нечувствительный к регистру)
        if ($request->filled('search')) {
            $search = mb_strtolower($request->input('search'));
            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(name) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(COALESCE(surname, \'\')) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(CONCAT(COALESCE(name, \'\'), \' \', COALESCE(surname, \'\'))) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(COALESCE(city, \'\')) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('CONCAT(COALESCE(country_code, \'\'), phone) LIKE ?', ["%{$search}%"])
                  ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        // Поддержка старых параметров для обратной совместимости
        if ($request->filled('name')) {
            $query->whereRaw('LOWER(name) LIKE ?', ['%' . mb_strtolower($request->input('name')) . '%']);
        }

        if ($request->filled('city')) {
            $query->whereRaw('LOWER(city) LIKE ?', ['%' . mb_strtolower($request->input('city')) . '%']);
        }

        if ($request->filled('phone')) {
            $query->where('phone', 'like', '%' . $request->input('phone') . '%');
        }

        // Сортировка
        $sortBy = $request->input('sort_by', 'created_at');
        $sortOrder = $request->input('sort_order', 'desc');
        
        // Разрешённые поля для сортировки
        $allowedSortFields = ['id', 'name', 'surname', 'phone', 'city', 'height', 'shoe_size', 'clothing_size', 'gifts_count', 'created_at'];
        
        // Проверяем, что поле разрешено
        if (!in_array($sortBy, $allowedSortFields)) {
            $sortBy = 'created_at';
        }
        
        // Проверяем направление сортировки
        $sortOrder = strtolower($sortOrder) === 'asc' ? 'asc' : 'desc';
        
        // Для gifts_count нужна особая обработка (это вычисляемое поле)
        if ($sortBy === 'gifts_count') {
            $query->orderBy('gifts_count', $sortOrder);
        } else {
            $query->orderBy($sortBy, $sortOrder);
        }

        $perPage = $request->input('per_page', 10);
        $users = $query->paginate($perPage);

        return response()->json($users);
    }
    public function getUsersCount(): JsonResponse
    {
        $users = User::get();
        $amount = "-";
        if ($users->count() > 100) {
            $amount = $users->count();
        }
        return response()->json(["amount" => $amount], 200);
    }

    public function setAvatarImageForUser(Request $request): JsonResponse
    {
        $request->validate([
            'file' => 'required|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);

        $user = $request->user();

        $filePath = $this->s3Service->getFilePath($request);

        $user->avatar_image = $filePath;
        $user->save();

        return response()->json([
            'message' => 'Аватарка успешно загружена!',
            'avatar_image' => $filePath
        ], 200);
    }

    public function myGifts(Request $request): JsonResponse
    {
        $user = $request->user();
        
        // Возвращаем подарки которые:
        // 1. Не активированы (is_activated = false)
        // 2. НЕ в статусе pending (pending - это подарки ожидающие выбора через QR)
        // 3. Либо status = null (старые подарки без статуса) 
        //    либо status = 'selected' (выбранные из группы)
        $gifts = $user->gifts()
            ->where('is_activated', false)
            ->where(function ($query) {
                $query->whereNull('status')
                      ->orWhere('status', '!=', 'pending');
            })
            ->get();

        // Также получаем pending подарки (ожидающие выбора в магазине)
        // Группируем их по gift_group_id
        $pendingGifts = $user->gifts()
            ->where('status', 'pending')
            ->orderBy('created_at', 'desc')
            ->get();

        $pendingGroups = [];
        foreach ($pendingGifts->groupBy('gift_group_id') as $groupId => $groupGifts) {
            $pendingGroups[] = [
                'gift_group_id' => $groupId,
                'gifts_count' => $groupGifts->count(),
                'created_at' => $groupGifts->first()->created_at,
                'gifts' => $groupGifts->map(function ($gift) {
                    return [
                        'id' => $gift->id,
                        'name' => $gift->name,
                        'image' => $gift->image,
                    ];
                })->values(),
            ];
        }

        return response()->json([
            'gifts' => $gifts,
            'pending_groups' => $pendingGroups,
            'has_pending' => count($pendingGroups) > 0,
        ], 200);
    }

    public function saveGift(Request $request): JsonResponse
    {
        $user = $request->user();
        $gift = Gift::find($request->gift_id);
        if ($gift->user_id != $user->id) {
            return response()->json([
                'message' => 'Подарок не принадлежит пользователю!'
            ], 403);
        }
        $gift->is_viewed = true;

        $gift->save();

        return response()->json([
            'message' => 'Подарок успешно сохранен!'
        ], 200);
    }

    public function activateGift(Request $request): JsonResponse
    {
        $user = $request->user();
        $gift = Gift::find($request->gift_id);
        if ($gift->user_id != $user->id) {
            return response()->json([
                'message' => 'Подарок не принадлежит пользователю!'
            ], 403);
        }
        $gift->is_activated = true;
        $gift->save();

        return response()->json([
            'message' => 'Подарок успешно активирован!'
        ], 200);
    }

    public function updateUser(Request $request): JsonResponse
    {
        $request->validate([
            'city' => 'required|string',
            'birthdate' => 'sometimes|date_format:Y-m-d',
            'height' => 'required|in:4,6,8',
            'clothing_size' => 'required|in:46,48,50,52,54,56,58,60,62,64',
            'shoe_size' => 'required|in:39,40,41,42,43,44,45,46',
            'name' => 'sometimes|string',
            'surname' => 'sometimes|string',
        ]);

        $user = $request->user();

        $user->city = $request->city;
        if ($request->has('birthdate')) {
            $user->birthdate = Carbon::createFromFormat('Y-m-d', $request->birthdate);
        }
        $user->height = $request->height;
        $user->clothing_size = $request->clothing_size;
        $user->shoe_size = $request->shoe_size;
        if ($request->has('name')) {
            $user->name = $request->name;
        }
        if ($request->has('surname')) {
            $user->surname = $request->surname;
        }

        $user->save();

        return response()->json([
            'message' => 'Данные пользователя успешно обновлены!',
            'user' => $user
        ], 200);
    }

    public function getUserInfo(Request $request): JsonResponse
    {
        $user = User::find($request->id);
        $referrer = null;
        if ($user->referrer_id != null && $user->referrer_id > 0) {
            $referrer = User::find($user->referrer_id);
            if ($referrer != null) {
                $user->referrer = $referrer->surname . " " . $referrer->name;
            }
        }

        $userData = $this->oneCApi->getClientInfo(str_replace('+7', '8', $user->country_code) . $user->phone);
        if ($userData) {
            $user->purchases_sum = $userData['purchasesAmount'] ?? 0;
            $user->purchases_count = $userData['purchasesCount'] ?? 0;
            $user->bonus_amount = $userData['bonusAmount'] ?? 0;
            $user->discount = $userData['personalDiscount'] ?? 0;
        } else {
            $user->purchases_sum = $user->transactions()->sum('amount');
            $user->purchases_count = 0;
        }
        $user->gift_certifacates_sum = $user->giftCertificates()->sum('nominal');
        $user->gifts_count = $user->gifts()->count();
        
        // Количество рефералов (пользователей, которых пригласил данный пользователь)
        $user->referrals_count = User::where('referrer_id', $user->id)->count();
        
        // Уровень лояльности из системы геймификации
        $loyaltyLevel = $user->currentLoyaltyLevel();
        if ($loyaltyLevel) {
            $user->loyalty_level = [
                'name' => $loyaltyLevel->name,
                'icon' => $loyaltyLevel->icon,
                'color' => $loyaltyLevel->color,
            ];
        } else {
            $user->loyalty_level = null;
        }
        
        // Последняя активность из таблицы sessions
        $lastSession = DB::table('sessions')
            ->where('user_id', $user->id)
            ->orderBy('last_activity', 'desc')
            ->first();
        
        if ($lastSession) {
            $user->last_activity = Carbon::createFromTimestamp($lastSession->last_activity)->toIso8601String();
        } else {
            // Если нет сессии, используем updated_at пользователя
            $user->last_activity = $user->updated_at ? $user->updated_at->toIso8601String() : null;
        }
        
        return response()->json($user);
    }

    public function getUsersWithRoles(Request $request)
    {
        $query = Admin::with('roles');
        
        // Сортировка
        $sortBy = $request->input('sort_by', 'id');
        $sortOrder = $request->input('sort_order', 'desc');
        
        // Разрешённые поля для сортировки
        $allowedSortFields = ['id', 'name', 'email', 'created_at'];
        
        if (!in_array($sortBy, $allowedSortFields)) {
            $sortBy = 'id';
        }
        
        $sortOrder = strtolower($sortOrder) === 'asc' ? 'asc' : 'desc';
        $query->orderBy($sortBy, $sortOrder);
        
        $users = $query->get()->map(function ($user) {
            return [
                'id' => $user->id,
                'name' => $user->name,
                'surname' => $user->surname ?? '',
                'email' => $user->email,
                'role' => $user->roles->pluck('name')->first() // Получаем только название роли
            ];
        });

        return response()->json($users);
    }

    public function updateSubscription(Request $request): JsonResponse
    {
        $user = $request->user();
        $deviceToken = $request->device_token;
        
        if ($deviceToken) {
            // Активируем токен для этого пользователя
            DeviceToken::activateForUser(
                $user->id,
                $deviceToken,
                $request->device_type ?? null,
                $request->device_info ?? null
            );
            $message = 'Подписка на push-уведомления активирована!';
        } else {
            // Деактивируем все токены пользователя
            DeviceToken::deactivateForUser($user->id);
            $message = 'Подписка на push-уведомления отключена!';
        }
        
        // Обновляем legacy поле для обратной совместимости
        $user->device_token = $deviceToken;
        $user->save();

        return response()->json([
            'message' => $message,
            'user' => $user,
            'is_active' => !empty($deviceToken),
        ], 200);
    }


    /**
     * @OA\Get(
     *     path="/admin/users-with-gifts",
     *     summary="Получение списка пользователей и количества их подарков",
     *     description="Позволяет фильтровать пользователей по имени и фамилии, городу или номеру телефона, возвращает количество подарков на каждого пользователя",
     *     tags={"Admin • Users"},
     *     @OA\Parameter(
     *         name="search",
     *         in="query",
     *         required=false,
     *         description="Поиск по имени и фамилии (в формате 'Имя Фамилия')",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Parameter(
     *         name="city",
     *         in="query",
     *         required=false,
     *         description="Фильтр по городу",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Parameter(
     *         name="phone",
     *         in="query",
     *         required=false,
     *         description="Фильтр по номеру телефона (с кодом страны)",
     *         @OA\Schema(type="string", example="+77011234567")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Список пользователей с количеством подарков",
     *         @OA\JsonContent(
     *             @OA\Property(property="current_page", type="integer", example=1),
     *             @OA\Property(property="data", type="array",
     *                 @OA\Items(
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="name", type="string", example="Иван"),
     *                     @OA\Property(property="surname", type="string", example="Иванов"),
     *                     @OA\Property(property="phone", type="string", example="7011234567"),
     *                     @OA\Property(property="city", type="string", example="Алматы"),
     *                     @OA\Property(property="gifts_count", type="integer", example=3)
     *                 )
     *             ),
     *             @OA\Property(property="total", type="integer", example=100),
     *             @OA\Property(property="last_page", type="integer", example=10),
     *             @OA\Property(property="per_page", type="integer", example=10)
     *         )
     *     )
     * )
     */
    public function getUsersWithGiftCount(Request $request)
    {
        $searchName = $request->input('search'); // имя + фамилия
        $city = $request->input('city');
        $phone = $request->input('phone');

        $users = DB::table('users')
            ->leftJoin('gifts', 'users.id', '=', 'gifts.user_id')
            ->select(
                'users.id',
                'users.name',
                'users.surname',
                'users.phone',
                'users.city',
                DB::raw('COUNT(gifts.id) as gifts_count')
            )
            ->when($searchName, function ($query, $searchName) {
                $query->where(DB::raw("CONCAT(users.name, ' ', users.surname)"), 'like', "%$searchName%");
            })
            ->when($city, function ($query, $city) {
                $query->where('users.city', 'like', "%$city%");
            })
            ->when($phone, function ($query, $phone) {
                $query->where(DB::raw("CONCAT(users.country_code, '', users.phone)"), 'like', "%$phone%");
            })
            ->groupBy('users.id', 'users.name', 'users.surname', 'users.phone', 'users.city')
            ->paginate(10);

        return response()->json($users);
    }

    /**
     * @OA\Get(
     *     path="/admin/users/{id}/gifts",
     *     summary="Детальная информация о пользователе и его подарках",
     *     description="Возвращает информацию о пользователе и список его подарков с изображениями",
     *     tags={"Admin • Users"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="ID пользователя",
     *         @OA\Schema(type="integer", example=1)
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Данные пользователя и его подарки",
     *         @OA\JsonContent(
     *             @OA\Property(property="user", type="object",
     *                 @OA\Property(property="name", type="string", example="Иван"),
     *                 @OA\Property(property="surname", type="string", example="Иванов")
     *             ),
     *             @OA\Property(property="gifts", type="array",
     *                 @OA\Items(
     *                     @OA\Property(property="name", type="string", example="Галстук"),
     *                     @OA\Property(property="image", type="string", example="https://s3.aws.com/ketroy/gifts/image.jpg")
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Пользователь не найден"
     *     )
     * )
     */
    public function show($id): JsonResponse
    {
        $user = User::with(['gifts']) // подгружаем подарки и связанные акции
            ->findOrFail($id);

        return response()->json([
            'user' => [
                'name' => $user->name,
                'surname' => $user->surname,
            ],
            'gifts' => $user->gifts->map(function ($gift) {
                return [
                    'name' => $gift->name,
                    'image' => $gift->image,
                ];
            }),
        ]);
    }

    /**
     * Получить историю покупок пользователя из 1С
     */
    public function getPurchaseHistory(Request $request, $id): JsonResponse
    {
        $user = User::findOrFail($id);
        
        // Формируем номер телефона в формате 1С (8XXXXXXXXXX)
        $phone = str_replace('+7', '8', $user->country_code) . $user->phone;
        
        $purchaseData = $this->oneCApi->getClientPurchases($phone);
        
        if (!$purchaseData || !isset($purchaseData['purchases'])) {
            return response()->json([
                'purchases' => []
            ]);
        }
        
        return response()->json([
            'purchases' => $purchaseData['purchases']
        ]);
    }

    /**
     * Изменить персональную скидку пользователя
     */
    public function updatePersonalDiscount(Request $request, $id): JsonResponse
    {
        $request->validate([
            'discount' => 'required|integer|min:0|max:100',
        ]);

        $user = User::findOrFail($id);
        $phone = str_replace('+7', '8', $user->country_code) . $user->phone;

        // Отправляем в 1С
        $result = $this->oneCApi->updateDiscount($phone, $request->discount);

        if (!$result) {
            return response()->json([
                'message' => 'Ошибка при обновлении скидки в 1С'
            ], 500);
        }

        // Обновляем локально
        $user->discount = $request->discount;
        $user->save();

        return response()->json([
            'message' => 'Персональная скидка успешно обновлена',
            'discount' => $request->discount
        ]);
    }

    /**
     * Начислить бонусы пользователю
     */
    public function addBonuses(Request $request, $id): JsonResponse
    {
        Log::info('[addBonuses] Called', [
            'user_id' => $id,
            'amount' => $request->amount,
            'trace_id' => uniqid()
        ]);
        
        $request->validate([
            'amount' => 'required|integer|min:1',
            'comment' => 'nullable|string|max:255',
            'withDelay' => 'nullable|boolean', // true = 14 дней, false = сразу
        ]);

        $user = User::findOrFail($id);
        $phone = str_replace('+7', '8', $user->country_code) . $user->phone;
        $withDelay = $request->boolean('withDelay', true); // По умолчанию с отсрочкой

        // Отправляем в 1С
        $result = $this->oneCApi->updateBonus(
            $phone,
            $request->amount,
            'add',
            Carbon::now()->format('Y-m-d\TH:i:s'),
            $request->comment ?? 'Начисление бонусов администратором',
            $withDelay
        );

        if (!$result) {
            return response()->json([
                'message' => 'Ошибка при начислении бонусов в 1С'
            ], 500);
        }

        // НЕ обновляем локально! Баланс обновится через webhook от 1С
        // Это предотвращает двойное начисление и двойные push-уведомления
        $user->refresh(); // Получаем актуальные данные

        $delayMessage = $withDelay ? ' (доступны через 14 дней)' : ' (доступны сразу)';
        
        return response()->json([
            'message' => 'Бонусы успешно начислены' . $delayMessage,
            'bonus_amount' => $user->bonus_amount + $request->amount, // Показываем ожидаемый баланс
            'withDelay' => $withDelay
        ]);
    }

    /**
     * Списать бонусы у пользователя
     */
    public function deductBonuses(Request $request, $id): JsonResponse
    {
        Log::info('[deductBonuses] Called', [
            'user_id' => $id,
            'amount' => $request->amount,
            'trace_id' => uniqid()
        ]);
        
        $request->validate([
            'amount' => 'required|integer|min:1',
            'comment' => 'nullable|string|max:255',
            'withDelay' => 'nullable|boolean',
        ]);

        $user = User::findOrFail($id);

        if ($user->bonus_amount < $request->amount) {
            return response()->json([
                'message' => 'Недостаточно бонусов для списания'
            ], 400);
        }

        $phone = str_replace('+7', '8', $user->country_code) . $user->phone;
        $withDelay = $request->boolean('withDelay', true);

        // Отправляем в 1С
        $result = $this->oneCApi->updateBonus(
            $phone,
            $request->amount,
            'write-off',
            Carbon::now()->format('Y-m-d\TH:i:s'),
            $request->comment ?? 'Списание бонусов администратором',
            $withDelay
        );

        if (!$result) {
            return response()->json([
                'message' => 'Ошибка при списании бонусов в 1С'
            ], 500);
        }

        // НЕ обновляем локально! Баланс обновится через webhook от 1С
        $user->refresh();

        return response()->json([
            'message' => 'Бонусы успешно списаны',
            'bonus_amount' => max(0, $user->bonus_amount - $request->amount) // Показываем ожидаемый баланс
        ]);
    }

    /**
     * Отправить подарки пользователю из каталога (до 4 штук)
     * Пользователь сможет выбрать один из них рандомно при активации
     */
    public function sendGift(Request $request, $id): JsonResponse
    {
        $request->validate([
            'gift_catalog_ids' => 'required|array|min:1|max:4',
            'gift_catalog_ids.*' => 'required|integer|exists:gift_catalog,id',
        ]);

        $user = User::findOrFail($id);
        $giftCatalogIds = array_unique($request->gift_catalog_ids);
        
        // Ограничиваем до 4 подарков
        $giftCatalogIds = array_slice($giftCatalogIds, 0, 4);
        
        // Генерируем уникальный ID группы для связи подарков
        $giftGroupId = \Illuminate\Support\Str::uuid()->toString();
        
        $createdGifts = [];
        
        foreach ($giftCatalogIds as $catalogId) {
            $catalogGift = GiftCatalog::findOrFail($catalogId);
            
            $gift = Gift::create([
                'user_id' => $user->id,
                'name' => $catalogGift->name,
                'description' => $catalogGift->description,
                'image' => $catalogGift->image,
                'is_viewed' => false,
                'is_activated' => false,
                'status' => Gift::STATUS_PENDING,
                'gift_group_id' => $giftGroupId,
                'gift_catalog_id' => $catalogId,
            ]);
            
            $createdGifts[] = $gift;
        }

        $count = count($createdGifts);
        $message = $count === 1 
            ? 'Подарок успешно отправлен' 
            : "Отправлено {$count} подарка(ов) на выбор";

        return response()->json([
            'message' => $message,
            'gifts' => $createdGifts,
            'gift_group_id' => $giftGroupId
        ]);
    }

    /**
     * Отправить тестовое push-уведомление пользователю
     */
    public function sendTestNotification($id): JsonResponse
    {
        $user = User::findOrFail($id);

        // Получаем АКТИВНЫЙ токен пользователя
        $activeToken = DeviceToken::getActiveTokenForUser($user->id);

        if (empty($activeToken)) {
            return response()->json([
                'success' => false,
                'message' => 'У пользователя нет активного устройства. Пользователь должен войти в мобильное приложение.'
            ], 400);
        }

        try {
            $firebaseService = app(\App\Services\FirebaseService::class);
            
            $success = $firebaseService->sendPushNotification(
                null,
                1,
                'test',
                $activeToken, // Используем активный токен
                '🔔 Тестовое уведомление',
                'Это тестовое уведомление от Ketroy. Если вы его видите — push-уведомления работают!'
            );

            if ($success) {
                Log::info('Test notification sent successfully', [
                    'user_id' => $user->id,
                    'device_token' => substr($activeToken, 0, 20) . '...'
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Тестовое уведомление успешно отправлено'
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Не удалось отправить уведомление. Проверьте логи сервера.'
            ], 500);

        } catch (\Exception $e) {
            Log::error('Failed to send test notification', [
                'user_id' => $user->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Ошибка при отправке уведомления: ' . $e->getMessage()
            ], 500);
        }
    }
}
