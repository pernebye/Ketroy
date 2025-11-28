<?php

namespace App\Http\Controllers;

use App\Jobs\SendGiftsByDateJob;
use App\Models\Promotion;
use App\Models\GiftCatalog;
use Illuminate\Http\JsonResponse;
use App\Models\PromotionGift;
use App\Services\GiftService;
use App\Services\S3Service;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Carbon\Carbon;

class PromotionController extends Controller
{
    protected GiftService $giftService;

    protected S3Service $s3Service;

    public function __construct(S3Service $s3Service, GiftService $giftService)
    {
        $this->s3Service = $s3Service;
        $this->giftService = $giftService;
    }



    /**
     * @OA\Get(
     *     path="/api/admin/promotions",
     *     summary="Получение списка активных акций",
     *     description="Возвращает список всех акций, которые не архивированы.",
     *     tags={"Акции"},
     *     @OA\Response(
     *         response=200,
     *         description="Список акций",
     *         @OA\JsonContent(
     *             type="array",
     *             @OA\Items(
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="type", type="string", example="accumulation"),
     *                 @OA\Property(property="settings", type="object", example={"min_amount": 100000, "max_amount": 300000}),
     *                 @OA\Property(property="start_date", type="string", format="date", example="2024-07-01"),
     *                 @OA\Property(property="end_date", type="string", format="date", example="2024-07-31"),
     *                 @OA\Property(property="is_archived", type="boolean", example=false),
     *                 @OA\Property(
     *                     property="gifts",
     *                     type="array",
     *                     @OA\Items(
     *                         @OA\Property(property="gift_name", type="string", example="Галстук"),
     *                         @OA\Property(property="image", type="string", description="Base64-изображение подарка", example="data:image/jpeg;base64,..."),
     *                         @OA\Property(property="min_amount", type="integer", example=100000),
     *                         @OA\Property(property="max_amount", type="integer", example=300000)
     *                     )
     *                 )
     *             )
     *         )
     *     )
     * )
     */
    public function index()
    {
        return response()->json(Promotion::where('is_archived', false)->paginate(10));
    }

    public function show($id): JsonResponse
    {
        $promotion = Promotion::with('gifts.giftCatalog')->findOrFail($id);
        return response()->json($promotion);
    }



    /**
     * @OA\Post(
     *     path="/api/admin/promotions",
     *     summary="Создание новой акции",
     *     description="Создаёт новую акцию и добавляет к ней подарки.",
     *     tags={"Акции"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="type", type="string", enum={"accumulation", "friend_discount", "date_based"}, example="accumulation"),
     *             @OA\Property(property="settings", type="object", example={"min_amount": 100000, "max_amount": 300000}),
     *             @OA\Property(property="start_date", type="string", format="date", example="2024-07-01"),
     *             @OA\Property(property="end_date", type="string", format="date", example="2024-07-31"),    
     *             @OA\Property(
     *                 property="gifts",
     *                 type="array",
     *                 @OA\Items(
     *                     @OA\Property(property="gift_name", type="string", example="Галстук"),
     *                     @OA\Property(property="image", type="string", description="Base64-изображение подарка", example="data:image/jpeg;base64,..."),
     *                     @OA\Property(property="min_amount", type="integer", example=100000),
     *                     @OA\Property(property="max_amount", type="integer", example=300000)
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Акция успешно создана",
     *         @OA\JsonContent(type="object",
     *             @OA\Property(property="message", type="string", example="Акция успешно создана"),
     *             @OA\Property(property="promotion", type="object",
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="type", type="string", example="accumulation"),
     *                 @OA\Property(property="settings", type="object", example={"min_amount": 100000, "max_amount": 300000}),
     *                 @OA\Property(property="start_date", type="string", format="date", example="2024-07-01"),
     *                 @OA\Property(property="end_date", type="string", format="date", example="2024-07-31"),
     *                 @OA\Property(property="is_archived", type="boolean", example=false),
     *                 @OA\Property(property="gifts", type="array",
     *                     @OA\Items(
     *                         @OA\Property(property="gift_name", type="string", example="Галстук"),
     *                         @OA\Property(property="image", type="string", description="Base64-изображение подарка", example="data:image/jpeg;base64,..."),
     *                         @OA\Property(property="min_amount", type="integer", example=100000),
     *                         @OA\Property(property="max_amount", type="integer", example=300000)
     *                     )
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(response=422, description="Ошибка валидации")
     * )
     */
    public function store(Request $request)
    {
        // Логируем входящие данные для отладки
        \Log::info('Promotion store request', ['data' => $request->all()]);

        $request->validate([
            'name' => 'required',
            'type' => ['required', Rule::in(['single_purchase', 'friend_discount', 'date_based', 'birthday', 'lottery'])],
            'settings' => 'nullable|array', // Nullable для date_based/lottery
            'settings.min_purchase_amount' => 'nullable|integer|min:0',
            'settings.discount_percent' => 'nullable|integer|min:0|max:100',
            'settings.duration_days' => 'nullable|integer|min:1',
            'settings.days_before' => 'nullable|integer|min:0',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'description' => 'nullable|string',
            'is_active' => 'nullable|boolean',
            'gift_ids' => 'nullable|array|max:4', // ID подарков из каталога (необязательно для birthday)
            'gift_ids.*' => 'required|integer|exists:gift_catalog,id',
            // Опционально: создание нового подарка на лету
            'new_gifts' => 'nullable|array',
            'new_gifts.*.name' => 'required|string|max:255',
            'new_gifts.*.image' => 'required|string', // Base64
            // Лотерея - Push-уведомления
            'push_title' => 'nullable|string|max:255',
            'push_text' => 'nullable|string',
            'push_send_at' => 'nullable|date',
            // Лотерея - Модальное окно
            'modal_title' => 'nullable|string|max:255',
            'modal_text' => 'nullable|string',
            'modal_image' => 'nullable|string', // Base64 or URL
            'modal_button_text' => 'nullable|string|max:100',
        ]);

        // Проверка: только одна активная акция типа birthday
        if ($request->type === 'birthday') {
            $existingBirthday = Promotion::where('type', 'birthday')
                ->where('is_archived', false)
                ->exists();
            if ($existingBirthday) {
                return response()->json([
                    'message' => 'Акция "День рождения" уже существует. Можно создать только одну такую акцию.'
                ], 422);
            }
        }

        // Проверка: только одна активная акция типа friend_discount
        if ($request->type === 'friend_discount') {
            $existingFriendDiscount = Promotion::where('type', 'friend_discount')
                ->where('is_archived', false)
                ->exists();
            if ($existingFriendDiscount) {
                return response()->json([
                    'message' => 'Акция "Подари скидку другу" уже существует. Можно создать только одну такую акцию.'
                ], 422);
            }
        }

        // Подготовка данных для создания
        $promotionData = $request->only([
            'name', 'type', 'settings', 'start_date', 'end_date', 'description', 'is_active',
            'push_title', 'push_text', 'push_send_at',
            'modal_title', 'modal_text', 'modal_button_text'
        ]);

        // Устанавливаем пустой массив если settings не передан
        if (empty($promotionData['settings'])) {
            $promotionData['settings'] = [];
        }

        // Обработка изображения модального окна
        if ($request->has('modal_image') && !empty($request->modal_image)) {
            $modalImagePath = $this->s3Service->uploadBase64($request->modal_image);
            $promotionData['modal_image'] = $modalImagePath;
        }

        $promotion = Promotion::create($promotionData);

        // Привязываем существующие подарки из каталога (если переданы)
        if ($request->has('gift_ids') && !empty($request->gift_ids)) {
            foreach ($request->gift_ids as $giftCatalogId) {
                $promotion->gifts()->create([
                    'gift_catalog_id' => $giftCatalogId,
                ]);
            }
        }

        // Создаём новые подарки на лету (если переданы)
        if ($request->has('new_gifts')) {
            foreach ($request->new_gifts as $newGift) {
                // Создаём подарок в каталоге
                $filePath = $this->s3Service->uploadBase64($newGift['image']);
                $catalogGift = GiftCatalog::create([
                    'name' => $newGift['name'],
                    'image' => $filePath,
                    'is_active' => true,
                ]);

                // Привязываем к акции
                $promotion->gifts()->create([
                    'gift_catalog_id' => $catalogGift->id,
                ]);
            }
        }

        if ($request->type == 'date_based' && ($request->end_date != null && $request->end_date == Carbon::now()->toDateString())) {
            SendGiftsByDateJob::dispatch($this->giftService);
        }

        return response()->json(['message' => 'Акция создана', 'promotion' => $promotion->load('gifts.giftCatalog')], 201);
    }

    /**
     * @OA\Post(
     *     path="/api/admin/promotions/{promotion}",
     *     summary="Обновление акции",
     *     description="Обновляет параметры акции и её подарки.",
     *     tags={"Акции"},
     *     @OA\Parameter(
     *         name="promotion",
     *         in="path",
     *         required=true,
     *         description="ID акции",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="type", type="string", enum={"accumulation", "friend_discount", "date_based"}, example="accumulation"),
     *             @OA\Property(property="settings", type="object", example={"min_amount": 100000, "max_amount": 300000}),
     *             @OA\Property(
     *                 property="gifts",
     *                 type="array",
     *                 @OA\Items(
     *                     @OA\Property(property="gift_name", type="string", example="Галстук"),
     *                     @OA\Property(property="image", type="string", description="Base64-изображение подарка", example="data:image/jpeg;base64,..."),
     *                     @OA\Property(property="min_amount", type="integer", example=100000),
     *                     @OA\Property(property="max_amount", type="integer", example=300000)
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Акция обновлена",
     *         @OA\JsonContent(type="object",
     *             @OA\Property(property="message", type="string", example="Акция успешно обновлена"),
     *             @OA\Property(property="promotion", type="object",
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="type", type="string", example="accumulation"),
     *                 @OA\Property(property="settings", type="object", example={"min_amount": 100000, "max_amount": 300000}),
     *                 @OA\Property(property="start_date", type="string", format="date", example="2024-07-01"),
     *                 @OA\Property(property="end_date", type="string", format="date", example="2024-07-31"),
     *                 @OA\Property(property="is_archived", type="boolean", example=false),
     *                 @OA\Property(property="gifts", type="array",
     *                     @OA\Items(
     *                         @OA\Property(property="gift_name", type="string", example="Галстук"),
     *                         @OA\Property(property="image", type="string", description="Base64-изображение подарка", example="data:image/jpeg;base64,..."),
     *                         @OA\Property(property="min_amount", type="integer", example=100000),
     *                         @OA\Property(property="max_amount", type="integer", example=300000)
     *                     )
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(response=404, description="Акция не найдена")
     * )
     */
    public function update(Request $request, $id)
    {
        $request->validate([
            'name' => 'required',
            'type' => ['required', Rule::in(['single_purchase', 'friend_discount', 'date_based', 'birthday', 'lottery'])],
            'settings' => 'nullable|array', // Nullable для date_based/lottery
            'settings.min_purchase_amount' => 'nullable|integer|min:0',
            'settings.discount_percent' => 'nullable|integer|min:0|max:100',
            'settings.duration_days' => 'nullable|integer|min:1',
            'settings.days_before' => 'nullable|integer|min:0',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'description' => 'nullable|string',
            'is_active' => 'nullable|boolean',
            'gift_ids' => 'nullable|array|max:4',
            'gift_ids.*' => 'required|integer|exists:gift_catalog,id',
            'new_gifts' => 'nullable|array',
            'new_gifts.*.name' => 'required|string|max:255',
            'new_gifts.*.image' => 'required|string',
            // Лотерея - Push-уведомления
            'push_title' => 'nullable|string|max:255',
            'push_text' => 'nullable|string',
            'push_send_at' => 'nullable|date',
            // Лотерея - Модальное окно
            'modal_title' => 'nullable|string|max:255',
            'modal_text' => 'nullable|string',
            'modal_image' => 'nullable|string', // Base64 or URL
            'modal_button_text' => 'nullable|string|max:100',
        ]);

        $promotion = Promotion::with('gifts')->findOrFail($id);

        // Проверка: если меняем тип на birthday, проверяем что нет другой такой акции
        if ($request->type === 'birthday' && $promotion->type !== 'birthday') {
            $existingBirthday = Promotion::where('type', 'birthday')
                ->where('is_archived', false)
                ->where('id', '!=', $id)
                ->exists();
            if ($existingBirthday) {
                return response()->json([
                    'message' => 'Акция "День рождения" уже существует. Можно создать только одну такую акцию.'
                ], 422);
            }
        }

        // Проверка: если меняем тип на friend_discount, проверяем что нет другой такой акции
        if ($request->type === 'friend_discount' && $promotion->type !== 'friend_discount') {
            $existingFriendDiscount = Promotion::where('type', 'friend_discount')
                ->where('is_archived', false)
                ->where('id', '!=', $id)
                ->exists();
            if ($existingFriendDiscount) {
                return response()->json([
                    'message' => 'Акция "Подари скидку другу" уже существует. Можно создать только одну такую акцию.'
                ], 422);
            }
        }

        // Подготовка данных для обновления
        $updateData = $request->only([
            'name', 'type', 'settings', 'start_date', 'end_date', 'description', 'is_active',
            'push_title', 'push_text', 'push_send_at',
            'modal_title', 'modal_text', 'modal_button_text'
        ]);

        // Устанавливаем пустой массив если settings не передан
        if (empty($updateData['settings'])) {
            $updateData['settings'] = [];
        }

        // Обработка изображения модального окна (только если передано новое)
        if ($request->has('modal_image') && !empty($request->modal_image)) {
            // Если это не URL (т.е. это base64), загружаем
            if (!str_starts_with($request->modal_image, 'http')) {
                $modalImagePath = $this->s3Service->uploadBase64($request->modal_image);
                $updateData['modal_image'] = $modalImagePath;
            }
        }

        // Сбрасываем push_sent если изменилась дата отправки
        if ($request->has('push_send_at') && $request->push_send_at !== $promotion->push_send_at?->toDateTimeString()) {
            $updateData['push_sent'] = false;
        }

        $promotion->update($updateData);

        // Обновляем привязки подарков если переданы
        if ($request->has('gift_ids') || $request->has('new_gifts')) {
            // Удаляем старые привязки (подарки в каталоге остаются!)
            $promotion->gifts()->delete();

            // Привязываем подарки из каталога
            if ($request->has('gift_ids')) {
                foreach ($request->gift_ids as $giftCatalogId) {
                    $promotion->gifts()->create([
                        'gift_catalog_id' => $giftCatalogId,
                    ]);
                }
            }

            // Создаём новые подарки на лету
            if ($request->has('new_gifts')) {
                foreach ($request->new_gifts as $newGift) {
                    $filePath = $this->s3Service->uploadBase64($newGift['image']);
                    $catalogGift = GiftCatalog::create([
                        'name' => $newGift['name'],
                        'image' => $filePath,
                        'is_active' => true,
                    ]);

                    $promotion->gifts()->create([
                        'gift_catalog_id' => $catalogGift->id,
                    ]);
                }
            }
        }

        return response()->json(['message' => 'Акция обновлена', 'promotion' => $promotion->load('gifts.giftCatalog')]);
    }

    /**
     * Переключение активности акции
     */
    public function toggleActive(Request $request, $id)
    {
        $request->validate([
            'is_active' => 'required|boolean',
        ]);

        $promotion = Promotion::findOrFail($id);
        $promotion->update(['is_active' => $request->is_active]);

        return response()->json([
            'message' => $request->is_active ? 'Акция активирована' : 'Акция деактивирована',
            'promotion' => $promotion->load('gifts.giftCatalog')
        ]);
    }

    /**
     * @OA\Post(
     *     path="/api/admin/promotions/{promotion}/archive",
     *     summary="Архивация акции",
     *     description="Помечает акцию как архивную.",
     *     tags={"Акции"},
     *     @OA\Parameter(
     *         name="promotion",
     *         in="path",
     *         required=true,
     *         description="ID акции",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Акция архивирована",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Акция архивирована")
     *         )
     *     ),
     *     @OA\Response(response=404, description="Акция не найдена")
     * )
     */
    public function archive($id)
    {
        $promotion = Promotion::findOrFail($id);
        $promotion->update(['is_archived' => !$promotion->is_archived, 'is_active' => false]);
        $message = $promotion->is_archived ? 'Акция архивирована' : 'Акция восстановлена из архива';
        return response()->json(['message' => $message, 'promotion' => $promotion->load('gifts.giftCatalog')]);
    }

    /**
     * Получение архивированных акций
     */
    public function archived()
    {
        return response()->json(Promotion::where('is_archived', true)->with('gifts.giftCatalog')->get());
    }

    /**
     * Полное удаление акции (только из архива)
     */
    public function destroy($id)
    {
        $promotion = Promotion::with('gifts')->findOrFail($id);
        
        if (!$promotion->is_archived) {
            return response()->json(['message' => 'Можно удалять только архивированные акции'], 422);
        }
        
        // Удаляем связанные подарки акции (не сами подарки из каталога)
        $promotion->gifts()->delete();
        $promotion->delete();
        
        return response()->json(['message' => 'Акция удалена']);
    }
}
