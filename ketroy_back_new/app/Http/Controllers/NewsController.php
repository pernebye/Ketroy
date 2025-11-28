<?php

namespace App\Http\Controllers;

use App\Events\NewsPublished;
use App\Events\UserInteractionEvent;
use App\Jobs\SendNewsPushJob;
use App\Jobs\UploadBlockMedia;
use App\Models\News;
use App\Models\User;
use App\Services\S3Service;
use App\Services\FirebaseService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

use Illuminate\Support\Facades\Log;
use Carbon\Carbon;


class NewsController extends Controller
{
    protected S3Service $s3Service;
    protected FirebaseService $firebaseService;

    public function __construct(S3Service $s3Service, FirebaseService $firebaseService)
    {
        $this->s3Service = $s3Service;
        $this->firebaseService = $firebaseService;
    }

    /**
     * @OA\Get(
     *     path="/news",
     *     summary="Получение списка новостей",
     *     description="Возвращает список активных новостей с возможностью фильтрации по параметрам.",
     *     tags={"News"},
     *     @OA\Parameter(
     *         name="city",
     *         in="query",
     *         required=false,
     *         description="Город для фильтрации новостей",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Parameter(
     *         name="category",
     *         in="query",
     *         required=false,
     *         description="Категория для фильтрации новостей",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Parameter(
     *         name="height",
     *         in="query",
     *         required=false,
     *         description="Рост для фильтрации новостей",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Parameter(
     *         name="clothing_size",
     *         in="query",
     *         required=false,
     *         description="Размер одежды для фильтрации новостей",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Parameter(
     *         name="shoe_size",
     *         in="query",
     *         required=false,
     *         description="Размер обуви для фильтрации новостей",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Список новостей",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="current_page", type="integer"),
     *             @OA\Property(property="data", type="array",
     *                 @OA\Items(
     *                     type="object",
     *                     @OA\Property(property="id", type="integer"),
     *                     @OA\Property(property="name", type="string"),
     *                     @OA\Property(property="description", type="string"),
     *                     @OA\Property(property="city", type="string"),
     *                     @OA\Property(property="type", type="string"),
     *                     @OA\Property(property="file_path", type="string"),
     *                     @OA\Property(property="is_active", type="boolean"),
     *                     @OA\Property(property="expired_at", type="string", format="date-time"),
     *                     @OA\Property(property="category", type="string"),
     *                     @OA\Property(property="height", type="integer"),
     *                     @OA\Property(property="clothing_size", type="integer"),
     *                     @OA\Property(property="shoe_size", type="integer")
     *                 )
     *             )
     *         )
     *     )
     * )
     */
    public function index(Request $request): JsonResponse
    {
        $city = $request->input('city');
        $category = $request->input('category');
        $clothingSize = $request->input('clothing_size');
        $shoeSize = $request->input('shoe_size');
        
        $news = News::with('blocks')
            ->where('is_active', true)
            ->where('published_at', '<=', now())
            ->where(function ($query) {
                $query->whereNull('expired_at')
                    ->orWhere('expired_at', '>=', now());
            })
            ->when($city && $city !== 'Все', function ($query) use ($city) {
                // Фильтр по городу - показываем новости содержащие город ИЛИ "Все" (PostgreSQL jsonb)
                return $query->where(function ($q) use ($city) {
                    $q->whereRaw("city @> ?", [json_encode([$city])])
                      ->orWhereRaw("city @> ?", [json_encode(['Все'])]);
                });
            })
            ->when($category && $category !== 'Все', function ($query) use ($category) {
                // Фильтр по категории - показываем новости содержащие категорию ИЛИ "Все" (PostgreSQL jsonb)
                return $query->where(function ($q) use ($category) {
                    $q->whereRaw("category @> ?", [json_encode([$category])])
                      ->orWhereRaw("category @> ?", [json_encode(['Все'])]);
                });
            })
            // Фильтр по размеру одежды - показываем новости, где размер совпадает ИЛИ размер = NULL/пусто/Все
            ->when($clothingSize, function ($query) use ($clothingSize) {
                return $query->where(function ($q) use ($clothingSize) {
                    $q->where('clothing_size', $clothingSize)
                      ->orWhereNull('clothing_size')
                      ->orWhere('clothing_size', '')
                      ->orWhere('clothing_size', 'Все');
                });
            })
            // Фильтр по размеру обуви - показываем новости, где размер совпадает ИЛИ размер = NULL/пусто/Все
            ->when($shoeSize, function ($query) use ($shoeSize) {
                return $query->where(function ($q) use ($shoeSize) {
                    $q->where('shoe_size', $shoeSize)
                      ->orWhereNull('shoe_size')
                      ->orWhere('shoe_size', '')
                      ->orWhere('shoe_size', 'Все');
                });
            })
            ->orderBy('sort_order', 'asc')
            ->orderBy('created_at', 'desc')
            ->paginate(10);

        // Санитизируем данные для корректного JSON
        $newsArray = $news->toArray();
        $newsArray['data'] = array_map([$this, 'sanitizeNewsItem'], $newsArray['data']);

        return response()->json($newsArray, 200, [], JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE);
    }

    /**
     * Санитизирует текстовые поля новости от некорректных unicode
     */
    private function sanitizeNewsItem(array $item): array
    {
        // Санитизируем блоки
        if (isset($item['blocks']) && is_array($item['blocks'])) {
            $item['blocks'] = array_map(function ($block) {
                if (isset($block['text'])) {
                    $block['text'] = $this->sanitizeText($block['text']);
                }
                return $block;
            }, $item['blocks']);
        }

        // Санитизируем основные текстовые поля (city и category теперь массивы, не трогаем их)
        foreach (['name', 'description'] as $field) {
            if (isset($item[$field]) && is_string($item[$field])) {
                $item[$field] = $this->sanitizeText($item[$field]);
            }
        }

        return $item;
    }

    /**
     * Очищает текст от некорректных unicode escape последовательностей
     */
    private function sanitizeText(?string $text): ?string
    {
        if ($text === null) {
            return null;
        }

        // Удаляем некорректные unicode escape последовательности (\uXXXX где XXXX невалидный)
        $text = preg_replace('/\\\\u[0-9a-fA-F]{0,3}(?![0-9a-fA-F])/', '', $text);
        
        // Конвертируем в UTF-8, заменяя невалидные символы
        $text = mb_convert_encoding($text, 'UTF-8', 'UTF-8');
        
        // Удаляем null bytes и другие проблемные символы
        $text = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F]/', '', $text);

        return $text;
    }

    /**
     * @OA\Get(
     *     path="/news/{id}",
     *     summary="Получение новости",
     *     description="Возвращает новость по указанному идентификатору.",
     *     tags={"News"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="ID новости",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Детали новости",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="id", type="integer"),
     *             @OA\Property(property="name", type="string"),
     *             @OA\Property(property="description", type="string"),
     *             @OA\Property(property="city", type="string"),
     *             @OA\Property(property="type", type="string"),
     *             @OA\Property(property="file_path", type="string"),
     *             @OA\Property(property="is_active", type="boolean"),
     *             @OA\Property(property="expired_at", type="string", format="date-time"),
     *             @OA\Property(property="category", type="string"),
     *             @OA\Property(property="height", type="integer"),
     *             @OA\Property(property="clothing_size", type="integer"),
     *             @OA\Property(property="shoe_size", type="integer")
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Новость не найдена"
     *     )
     * )
     */
    public function show($id): JsonResponse
    {
        $news = News::with('blocks')->findOrFail($id);
        event(new UserInteractionEvent("post", ['id' => $id, 'name' => $news->name], null));
        
        // Санитизируем данные
        $newsArray = $this->sanitizeNewsItem($news->toArray());
        
        return response()->json($newsArray, 200, [], JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE);
    }

    /**
     * @OA\Post(
     *     path="/news",
     *     summary="Создание новости",
     *     description="Создает новую новость.",
     *     tags={"News"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"is_active", "name", "category", "type"},
     *             @OA\Property(property="is_active", type="boolean"),
     *             @OA\Property(property="name", type="string"),
     *             @OA\Property(property="description", type="string"),
     *             @OA\Property(property="category", type="string"),
     *             @OA\Property(property="height", type="integer"),
     *             @OA\Property(property="clothing_size", type="integer"),
     *             @OA\Property(property="shoe_size", type="integer"),
     *             @OA\Property(property="city", type="string"),
     *             @OA\Property(property="type", type="string", enum={"image", "video"}),
     *             @OA\Property(property="expired_at", type="string", format="date"),
     *             @OA\Property(property="file_path", type="string"),
     *             @OA\Property(property="file", type="string", format="binary")
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Новость успешно создана",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Новость успешно создана"),
     *             @OA\Property(property="news", type="object",
     *                 @OA\Property(property="id", type="integer"),
     *                 @OA\Property(property="name", type="string"),
     *                 @OA\Property(property="description", type="string"),
     *                 @OA\Property(property="city", type="string"),
     *                 @OA\Property(property="type", type="string"),
     *                 @OA\Property(property="file_path", type="string"),
     *                 @OA\Property(property="is_active", type="boolean"),
     *                 @OA\Property(property="expired_at", type="string", format="date-time"),
     *                 @OA\Property(property="category", type="string"),
     *                 @OA\Property(property="height", type="integer"),
     *                 @OA\Property(property="clothing_size", type="integer"),
     *                 @OA\Property(property="shoe_size", type="integer")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Ошибка валидации"
     *     )
     * )
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'is_active' => 'required|boolean',
            'name' => 'required|string|max:255',
            'category' => 'required',  // массив или строка
            'height' => 'nullable|string',
            'clothing_size' => 'nullable|string',
            'shoe_size' => 'nullable|string',
            'city' => 'required',  // массив или строка
            'expired_at' => 'nullable|date',
            'published_at' => 'nullable|date',
            'blocks' => 'required|array|min:1',
            'blocks.*.text' => 'nullable|string',
            'blocks.*.file' => 'nullable|string',
            'blocks.*.resolution' => 'nullable|string',
        ]);

        // Конвертируем city и category в массивы, если они строки
        $city = $validated['city'];
        $category = $validated['category'];
        
        if (is_string($city)) {
            $city = [$city];
        }
        if (is_string($category)) {
            $category = [$category];
        }

        $news = News::create(array_merge($validated, [
            'city' => $city,
            'category' => $category,
            'published_at' => $validated['published_at'] ?? now(),
        ]));


        foreach ($request->blocks as $index => $block) {
            $blockModel = $news->blocks()->create([
                'media_path' => null, // пока пусто
                'text' => $block['text'] ?? null,
                'order' => $index,
                'resolution' => $block['resolution'] ?? null,
            ]);

            if (!empty($block['file'])) {
                // Выполняем синхронно, чтобы media_path был доступен сразу
                UploadBlockMedia::dispatchSync($blockModel->id, $block['file']);
            }
        }
        
        // Отправляем уведомление только если:
        // 1. Новость активна
        // 2. published_at <= сегодня (т.е. публикуется сейчас или в прошлом)
        // Если published_at в будущем - планировщик отправит уведомление в 10:00 нужного дня
        if ($request->is_active) {
            $publishedAt = $news->published_at 
                ? Carbon::parse($news->published_at)->startOfDay() 
                : Carbon::today();
            $today = Carbon::today('Asia/Almaty');
            
            if ($publishedAt->lte($today)) {
                SendNewsPushJob::dispatch($news->id);
                Log::info("NewsController: Немедленная отправка уведомления для новости ID {$news->id}");
            } else {
                Log::info("NewsController: Уведомление для новости ID {$news->id} запланировано на {$publishedAt->toDateString()} в 10:00");
            }
        }

        return response()->json([
            'message' => 'Новость с блоками успешно создана',
            'news' => $news->fresh()->load('blocks')
        ], 201);
    }

    /**
     * @OA\Put(
     *     path="/news/{id}",
     *     summary="Обновление новости",
     *     description="Обновляет существующую новость.",
     *     tags={"News"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="ID новости",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"is_active", "name", "category", "type"},
     *             @OA\Property(property="is_active", type="boolean"),
     *             @OA\Property(property="name", type="string"),
     *             @OA\Property(property="description", type="string"),
     *             @OA\Property(property="category", type="string"),
     *             @OA\Property(property="height", type="integer"),
     *             @OA\Property(property="clothing_size", type="integer"),
     *             @OA\Property(property="shoe_size", type="integer"),
     *             @OA\Property(property="city", type="string"),
     *             @OA\Property(property="type", type="string", enum={"image", "video"}),
     *             @OA\Property(property="expired_at", type="string", format="date"),
     *             @OA\Property(property="file_path", type="string"),
     *             @OA\Property(property="file", type="string", format="binary")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Новость успешно обновлена",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Новость успешно изменена"),
     *             @OA\Property(property="news", type="object",
     *                 @OA\Property(property="id", type="integer"),
     *                 @OA\Property(property="name", type="string"),
     *                 @OA\Property(property="description", type="string"),
     *                 @OA\Property(property="city", type="string"),
     *                 @OA\Property(property="type", type="string"),
     *                 @OA\Property(property="file_path", type="string"),
     *                 @OA\Property(property="is_active", type="boolean"),
     *                 @OA\Property(property="expired_at", type="string", format="date-time"),
     *                 @OA\Property(property="category", type="string"),
     *                 @OA\Property(property="height", type="integer"),
     *                 @OA\Property(property="clothing_size", type="integer"),
     *                 @OA\Property(property="shoe_size", type="integer")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Новость не найдена"
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Ошибка валидации"
     *     )
     * )
     */
    public function update(Request $request, $id): JsonResponse
    {
        $request->validate([
            'is_active' => 'required|boolean',
            'name' => 'required|string|max:255',
            'category' => 'required',  // массив или строка
            'height' => 'nullable|string',
            'clothing_size' => 'nullable|string|max:255',
            'shoe_size' => 'nullable|string',
            'city' => 'required',  // массив или строка
            'expired_at' => 'nullable|date',
            'published_at' => 'nullable|date',
            'blocks' => 'nullable|array',
            'blocks.*.text' => 'nullable|string',
            'blocks.*.file' => 'nullable|string',
            'blocks.*.resolution' => 'nullable|string',
        ]);

        $news = News::findOrFail($id);
        
        // Сохраняем предыдущее состояние активности
        $wasActive = $news->is_active;

        // Конвертируем city и category в массивы, если они строки
        $city = $request->city;
        $category = $request->category;
        
        if (is_string($city)) {
            $city = [$city];
        }
        if (is_string($category)) {
            $category = [$category];
        }

        $updateData = [
            'name' => $request->name,
            'city' => $city,
            'is_active' => $request->is_active ?? true,
            'expired_at' => $request->expired_at,
            'category' => $category,
            'height' => $request->height,
            'clothing_size' => $request->clothing_size,
            'shoe_size' => $request->shoe_size,
            'published_at' => $request->published_at ?? now(),
        ];
        
        // Если новость становится активной после деактивации - сбрасываем флаг отправки
        if (!$wasActive && $request->is_active) {
            $updateData['notification_sent'] = false;
        }

        $news->update($updateData);

        if ($request->has('blocks')) {
            $news->blocks()->delete();

            foreach ($request->blocks as $index => $block) {
                $mediaPath = null;
                if (!empty($block['file']) && str_starts_with($block['file'], "https://")) {
                    $mediaPath = $block['file'];
                }

                $blockModel = $news->blocks()->create([
                    'media_path' => $mediaPath,
                    'text' => $block['text'] ?? null,
                    'order' => $index,
                    'resolution' => $block['resolution'] ?? null,
                ]);

                if (!empty($block['file']) && !str_starts_with($block['file'], "https://")) {
                    // Выполняем синхронно, чтобы media_path был доступен сразу
                    UploadBlockMedia::dispatchSync($blockModel->id, $block['file']);
                }
            }
        }

        // Проверяем, нужно ли отправить уведомление
        // Отправляем если:
        // 1. Новость активна
        // 2. Была деактивирована и теперь активируется (переопубликация) ИЛИ уведомление еще не было отправлено
        // 3. published_at <= сегодня
        $news->refresh();
        
        $shouldSendNotification = $news->is_active && (!$wasActive || !$news->notification_sent);
        
        if ($shouldSendNotification) {
            $publishedAt = $news->published_at 
                ? Carbon::parse($news->published_at)->startOfDay() 
                : Carbon::today();
            $today = Carbon::today('Asia/Almaty');
            
            if ($publishedAt->lte($today)) {
                SendNewsPushJob::dispatch($news->id);
                Log::info("NewsController update: Отправка уведомления для новости ID {$news->id}", [
                    'was_active' => $wasActive,
                    'is_republish' => !$wasActive,
                ]);
            }
        }

        return response()->json([
            'message' => 'Новость успешно изменена',
            'news' => $news->fresh()->load('blocks'),
        ]);
    }
    /**
     * @OA\Delete(
     *     path="/news/{id}",
     *     summary="Удаление новости",
     *     description="Удаляет новость по указанному идентификатору.",
     *     tags={"News"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="ID новости",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=204,
     *         description="Новость успешно удалена"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Новость не найдена"
     *     )
     * )
     */
    public function destroy($id): JsonResponse
    {
        $news = News::with('blocks')->findOrFail($id);

        // Удаление всех связанных блоков
        $news->blocks()->delete();

        // Удаление самой новости
        $news->delete();

        return response()->json(['message' => 'Новость успешно удалена']);
    }

    /**
     * Быстрое обновление отдельных полей новости
     */
    public function quickUpdate(Request $request, $id): JsonResponse
    {
        $news = News::findOrFail($id);
        
        $request->validate([
            'is_active' => 'sometimes|boolean',
        ]);

        $wasActive = $news->is_active;
        $updateData = [];
        
        if ($request->has('is_active')) {
            $updateData['is_active'] = $request->is_active;
        }

        // Если новость становится активной после деактивации - сбрасываем флаг отправки
        // чтобы уведомление отправилось снова при переопубликации
        if (!$wasActive && $request->is_active) {
            $updateData['notification_sent'] = false;
        }

        $news->update($updateData);
        $news->refresh();

        // Если новость только что стала активной - отправляем уведомление
        if (!$wasActive && $news->is_active) {
            $publishedAt = $news->published_at 
                ? Carbon::parse($news->published_at)->startOfDay() 
                : Carbon::today();
            $today = Carbon::today('Asia/Almaty');
            
            if ($publishedAt->lte($today)) {
                SendNewsPushJob::dispatch($news->id);
                Log::info("NewsController quickUpdate: Отправка уведомления для переопубликованной новости ID {$news->id}");
            }
        }

        return response()->json([
            'message' => 'Новость обновлена',
            'news' => $news->fresh()
        ]);
    }

    /**
     * @OA\Get(
     *     path="/admin/news",
     *     summary="Получение списка новостей",
     *     description="Возвращает список активных новостей с возможностью фильтрации по параметрам.",
     *     tags={"News"},
     *     @OA\Parameter(
     *         name="city",
     *         in="query",
     *         required=false,
     *         description="Город для фильтрации новостей",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Parameter(
     *         name="category",
     *         in="query",
     *         required=false,
     *         description="Категория для фильтрации новостей",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Parameter(
     *         name="height",
     *         in="query",
     *         required=false,
     *         description="Рост для фильтрации новостей",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Parameter(
     *         name="clothing_size",
     *         in="query",
     *         required=false,
     *         description="Размер одежды для фильтрации новостей",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Parameter(
     *         name="shoe_size",
     *         in="query",
     *         required=false,
     *         description="Размер обуви для фильтрации новостей",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Список новостей",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="current_page", type="integer"),
     *             @OA\Property(property="data", type="array",
     *                 @OA\Items(
     *                     type="object",
     *                     @OA\Property(property="id", type="integer"),
     *                     @OA\Property(property="name", type="string"),
     *                     @OA\Property(property="description", type="string"),
     *                     @OA\Property(property="city", type="string"),
     *                     @OA\Property(property="type", type="string"),
     *                     @OA\Property(property="file_path", type="string"),
     *                     @OA\Property(property="is_active", type="boolean"),
     *                     @OA\Property(property="expired_at", type="string", format="date-time"),
     *                     @OA\Property(property="category", type="string"),
     *                     @OA\Property(property="height", type="integer"),
     *                     @OA\Property(property="clothing_size", type="integer"),
     *                     @OA\Property(property="shoe_size", type="integer")
     *                 )
     *             )
     *         )
     *     )
     * )
     */
    public function getAllNews(Request $request): JsonResponse
    {
        $city = $request->input('city');
        $category = $request->input('category');
        
        $news = News::with('blocks')
            ->where('is_archived', false) // Не показываем архивированные
            ->when($city && $city !== 'Все', fn($q) => $q->whereRaw("city @> ?", [json_encode([$city])]))
            ->when($category && $category !== 'Все', fn($q) => $q->whereRaw("category @> ?", [json_encode([$category])]))
            ->when($request->input('height'), fn($q, $v) => $q->where('height', $v))
            ->when($request->input('clothing_size'), fn($q, $v) => $q->where('clothing_size', $v))
            ->when($request->input('shoe_size'), fn($q, $v) => $q->where('shoe_size', $v))
            ->orderBy('sort_order', 'asc')
            ->orderBy('created_at', 'desc')->get();

        return response()->json($news);
    }

    /**
     * Получение архивированных новостей
     */
    public function getArchivedNews(Request $request): JsonResponse
    {
        $news = News::with('blocks')
            ->where('is_archived', true)
            ->orderBy('updated_at', 'desc')
            ->get();

        return response()->json($news);
    }

    /**
     * Архивация новости
     */
    public function archive($id): JsonResponse
    {
        $news = News::findOrFail($id);
        
        $news->update([
            'is_archived' => true,
            'is_active' => false, // Автоматически деактивируем
        ]);

        return response()->json([
            'message' => 'Новость перемещена в архив',
            'news' => $news->fresh()
        ]);
    }

    /**
     * Массовая архивация новостей
     */
    public function archiveMany(Request $request): JsonResponse
    {
        $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'integer|exists:news,id'
        ]);

        News::whereIn('id', $request->ids)->update([
            'is_archived' => true,
            'is_active' => false,
        ]);

        return response()->json([
            'message' => 'Новости перемещены в архив'
        ]);
    }

    /**
     * Восстановление новости из архива
     */
    public function restore($id): JsonResponse
    {
        $news = News::findOrFail($id);
        
        // Сбрасываем флаг уведомления при восстановлении из архива
        // чтобы уведомление отправилось снова
        $news->update([
            'is_archived' => false,
            'notification_sent' => false,
        ]);

        $news->refresh();

        // Если новость активна - отправляем уведомление
        if ($news->is_active) {
            $publishedAt = $news->published_at 
                ? Carbon::parse($news->published_at)->startOfDay() 
                : Carbon::today();
            $today = Carbon::today('Asia/Almaty');
            
            if ($publishedAt->lte($today)) {
                SendNewsPushJob::dispatch($news->id);
                Log::info("NewsController restore: Отправка уведомления для восстановленной новости ID {$news->id}");
            }
        }

        return response()->json([
            'message' => 'Новость восстановлена из архива',
            'news' => $news->fresh()
        ]);
    }

    /**
     * @OA\Post(
     *     path="/admin/news/reorder",
     *     summary="Изменение порядка новостей",
     *     description="Обновляет порядок отображения новостей",
     *     tags={"News"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"news"},
     *             @OA\Property(
     *                 property="news",
     *                 type="array",
     *                 @OA\Items(
     *                     @OA\Property(property="id", type="integer"),
     *                     @OA\Property(property="sort_order", type="integer")
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Порядок успешно обновлён"
     *     )
     * )
     */
    public function reorder(Request $request): JsonResponse
    {
        $request->validate([
            'news' => 'required|array',
            'news.*.id' => 'required|integer|exists:news,id',
            'news.*.sort_order' => 'required|integer|min:0'
        ]);

        foreach ($request->news as $newsData) {
            News::where('id', $newsData['id'])
                ->update(['sort_order' => $newsData['sort_order']]);
        }

        return response()->json([
            'message' => 'Порядок новостей обновлён'
        ], 200);
    }
}
