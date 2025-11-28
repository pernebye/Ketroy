<?php

namespace App\Http\Controllers;

use App\Events\UserInteractionEvent;
use App\Models\Banner;
use App\Services\S3Service;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class BannerController extends Controller
{
    protected S3Service $s3Service;

    public function __construct(S3Service $s3Service)
    {
        $this->s3Service = $s3Service;
    }

    /**
     * @OA\Get(
     *     path="/banners",
     *     summary="Получение списка активных баннеров",
     *     description="Возвращает список активных баннеров, доступных для указанного города, если задан.",
     *     tags={"Banners"},
     *     @OA\Parameter(
     *         name="city",
     *         in="query",
     *         description="Фильтр баннеров по городу",
     *         required=false,
     *         @OA\Schema(type="string", example="Москва")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Список баннеров"
     *     )
     * )
     */
    public function index(Request $request): JsonResponse
    {
        $city = $request->input('city');
        
        $banners = Banner::query()
            ->where('is_active', true)
            ->where(function ($query) {
                // Проверка start_date: показывать только если дата начала наступила или не указана
                $query->whereNull('start_date')
                    ->orWhere('start_date', '<=', now());
            })
            ->where(function ($query) {
                // Проверка expired_at: показывать только если дата окончания не наступила или не указана
                $query->whereNull('expired_at')
                    ->orWhere('expired_at', '>', now());
            })
            ->when($city, function ($query) use ($city) {
                // Фильтр по городу - проверяем JSON массив cities
                return $query->where(function ($q) use ($city) {
                    $q->whereJsonContains('cities', $city)
                      ->orWhereJsonContains('cities', 'Все');
                });
            })
            ->orderBy('sort_order', 'asc')
            ->orderBy('created_at', 'asc')
            ->paginate(10);

        return response()->json($banners);
    }

    /**
     * @OA\Post(
     *     path="/banners",
     *     summary="Создание нового баннера",
     *     description="Создает новый баннер с указанием всех обязательных данных.",
     *     tags={"Banners"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"name", "city", "type"},
     *             @OA\Property(property="name", type="string", example="Рекламный баннер"),
     *             @OA\Property(property="description", type="string", example="Описание баннера"),
     *             @OA\Property(property="city", type="string", example="Москва"),
     *             @OA\Property(property="type", type="string", enum={"image", "video"}, example="image"),
     *             @OA\Property(property="is_active", type="boolean", example=true),
     *             @OA\Property(property="expired_at", type="string", format="date", example="2024-12-31"),
     *             @OA\Property(property="file", type="string", format="binary")
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Баннер успешно создан",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Баннер успешно создан")
     *         )
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Ошибка валидации"
     *     )
     * )
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'cities' => 'required|array',
            'cities.*' => 'string',
            'is_active' => 'boolean',
            'start_date' => 'nullable|date',
            'expired_at' => 'nullable|date',
            'sort_order' => 'nullable|integer',
            'file_path' => 'required|string',
        ]);

        // Определяем тип файла (image или gif)
        $filePath = $request->file_path;
        $type = 'image';
        if (str_contains(strtolower($filePath), '.gif')) {
            $type = 'gif';
        }

        // Если это base64, загружаем на S3
        if (!str_starts_with($filePath, 'http')) {
            $filePath = $this->s3Service->uploadBase64($filePath);
        }

        $banner = Banner::create([
            'name' => $request->name,
            'description' => $request->description,
            'cities' => $request->cities,
            'type' => $type,
            'file_path' => $filePath,
            'is_active' => $request->is_active ?? true,
            'start_date' => $request->start_date,
            'expired_at' => $request->expired_at,
            'sort_order' => $request->sort_order ?? 0,
        ]);

        return response()->json([
            'message' => 'Баннер успешно создан',
            'banner' => $banner
        ], 201);
    }

    /**
     * @OA\Get(
     *     path="/banners/{id}",
     *     summary="Получение информации о баннере",
     *     description="Возвращает данные баннера по его идентификатору.",
     *     tags={"Banners"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         description="ID баннера",
     *         required=true,
     *         @OA\Schema(type="integer", example=1)
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Данные баннера"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Баннер не найден"
     *     )
     * )
     */
    public function show($id): JsonResponse
    {
        $banner = Banner::findOrFail($id);
        event(new UserInteractionEvent("banner", ['id' => $id, 'name' => $banner->name], null));
        return response()->json($banner);
    }

    /**
     * @OA\Put(
     *     path="/banners/{id}",
     *     summary="Обновление баннера",
     *     description="Обновляет данные существующего баннера.",
     *     tags={"Banners"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         description="ID баннера",
     *         required=true,
     *         @OA\Schema(type="integer", example=1)
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"name", "city", "type"},
     *             @OA\Property(property="name", type="string", example="Обновленный баннер"),
     *             @OA\Property(property="description", type="string", example="Обновленное описание"),
     *             @OA\Property(property="city", type="string", example="Москва"),
     *             @OA\Property(property="type", type="string", enum={"image", "video"}, example="image"),
     *             @OA\Property(property="is_active", type="boolean", example=true),
     *             @OA\Property(property="expired_at", type="string", format="date", example="2024-12-31"),
     *             @OA\Property(property="file", type="string", format="binary")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Баннер успешно изменен",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Баннер успешно изменен")
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Баннер не найден"
     *     )
     * )
     */
    public function update(Request $request, $id): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'cities' => 'required|array',
            'cities.*' => 'string',
            'is_active' => 'boolean',
            'start_date' => 'nullable|date',
            'expired_at' => 'nullable|date',
            'sort_order' => 'nullable|integer',
            'file_path' => 'required|string',
        ]);

        $filePath = $request->file_path;
        $type = 'image';
        if (str_contains(strtolower($filePath), '.gif')) {
            $type = 'gif';
        }

        // Если это base64, загружаем на S3
        if (!str_starts_with($filePath, 'http')) {
            $filePath = $this->s3Service->uploadBase64($filePath);
        }

        Banner::where('id', $id)->update([
            'name' => $request->name,
            'description' => $request->description,
            'cities' => $request->cities,
            'type' => $type,
            'file_path' => $filePath,
            'is_active' => $request->is_active ?? true,
            'start_date' => $request->start_date,
            'expired_at' => $request->expired_at,
            'sort_order' => $request->sort_order ?? 0,
        ]);

        $banner = Banner::find($id);

        return response()->json([
            'message' => 'Баннер успешно изменен',
            'banner' => $banner
        ], 200);
    }

    /**
     * @OA\Delete(
     *     path="/banners/{id}",
     *     summary="Удаление баннера",
     *     description="Удаляет баннер по его идентификатору.",
     *     tags={"Banners"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         description="ID баннера",
     *         required=true,
     *         @OA\Schema(type="integer", example=1)
     *     ),
     *     @OA\Response(
     *         response=204,
     *         description="Баннер успешно удален"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Баннер не найден"
     *     )
     * )
     */
    public function destroy($id): JsonResponse
    {
        $banner = Banner::findOrFail($id);
        $banner->delete();
        return response()->json(null, 204);
    }

    /**
     * @OA\Get(
     *     path="/admin/banners",
     *     summary="Получение списка баннеров с пагинацией",
     *     tags={"Banners"},
     *     @OA\Parameter(
     *         name="city",
     *         in="query",
     *         required=false,
     *         description="Фильтр по городу",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Parameter(
     *         name="per_page",
     *         in="query",
     *         required=false,
     *         description="Количество баннеров на странице (по умолчанию 10)",
     *         @OA\Schema(type="integer", default=10)
     *     ),
     *     @OA\Parameter(
     *         name="page",
     *         in="query",
     *         required=false,
     *         description="Номер страницы (по умолчанию 1)",
     *         @OA\Schema(type="integer", default=1)
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Успешный ответ",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="data", type="array", @OA\Items(ref="#/components/schemas/Banner")),
     *             @OA\Property(property="current_page", type="integer", example=1),
     *             @OA\Property(property="per_page", type="integer", example=10),
     *             @OA\Property(property="total", type="integer", example=50),
     *             @OA\Property(property="last_page", type="integer", example=5)
     *         )
     *     ),
     *     @OA\Response(response=400, description="Ошибка запроса")
     * )
     */
    public function getAllBanners(Request $request): JsonResponse
    {
        $city = $request->input('city');
        
        $banners = Banner::query()
            ->when($city, function ($query) use ($city) {
                return $query->whereJsonContains('cities', $city);
            })
            ->orderBy('sort_order', 'asc')
            ->orderBy('created_at', 'asc')
            ->paginate($request->input('per_page', 50), ['*'], 'page', $request->input('page', 1));

        return response()->json([
            'data' => $banners->items(),
            'current_page' => $banners->currentPage(),
            'per_page' => $banners->perPage(),
            'total' => $banners->total(),
            'last_page' => $banners->lastPage()
        ]);
    }

    /**
     * Быстрое обновление отдельных полей баннера
     */
    public function quickUpdate(Request $request, $id): JsonResponse
    {
        $banner = Banner::findOrFail($id);
        
        $request->validate([
            'name' => 'sometimes|string|max:255',
            'cities' => 'sometimes|array',
            'cities.*' => 'string',
            'is_active' => 'sometimes|boolean',
            'start_date' => 'sometimes|nullable|date',
            'expired_at' => 'sometimes|nullable|date',
            'sort_order' => 'sometimes|nullable|integer',
            'file_path' => 'sometimes|string',
        ]);

        $updateData = [];
        
        if ($request->has('name')) {
            $updateData['name'] = $request->name;
        }
        if ($request->has('cities')) {
            $updateData['cities'] = $request->cities;
        }
        if ($request->has('is_active')) {
            $updateData['is_active'] = $request->is_active;
        }
        if ($request->has('start_date')) {
            $updateData['start_date'] = $request->start_date;
        }
        if ($request->has('expired_at')) {
            $updateData['expired_at'] = $request->expired_at;
        }
        if ($request->has('sort_order')) {
            $updateData['sort_order'] = $request->sort_order;
        }
        if ($request->has('file_path')) {
            $filePath = $request->file_path;
            if (!str_starts_with($filePath, 'http')) {
                $filePath = $this->s3Service->uploadBase64($filePath);
            }
            $updateData['file_path'] = $filePath;
            $updateData['type'] = str_contains(strtolower($filePath), '.gif') ? 'gif' : 'image';
        }

        $banner->update($updateData);

        return response()->json([
            'message' => 'Баннер обновлен',
            'banner' => $banner->fresh()
        ]);
    }

    /**
     * @OA\Post(
     *     path="/admin/banners/reorder",
     *     summary="Изменение порядка баннеров",
     *     description="Обновляет порядок отображения баннеров",
     *     tags={"Banners"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"banners"},
     *             @OA\Property(
     *                 property="banners",
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
            'banners' => 'required|array',
            'banners.*.id' => 'required|integer|exists:banners,id',
            'banners.*.sort_order' => 'required|integer|min:0'
        ]);

        foreach ($request->banners as $bannerData) {
            Banner::where('id', $bannerData['id'])
                ->update(['sort_order' => $bannerData['sort_order']]);
        }

        return response()->json([
            'message' => 'Порядок баннеров обновлён'
        ], 200);
    }
}

