<?php

namespace App\Http\Controllers;

use App\Models\News;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;

class CategoryController extends Controller
{
    /**
     * @OA\Get(
     *     path="/categories",
     *     summary="Получение списка категорий",
     *     description="Возвращает список категорий, которые хранятся в файле categories.json. Возвращает только категории с активными новостями.",
     *     tags={"Categories"},
     *     @OA\Response(
     *         response=200,
     *         description="Список категорий",
     *         @OA\JsonContent(
     *             type="array",
     *             @OA\Items(
     *                 type="object",
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="name", type="string", example="Категория 1")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Файл с категориями не найден"
     *     )
     * )
     */
    public function getCategories(Request $request): JsonResponse
    {
        $categoriesJson = Storage::disk('local')->get('categories.json');
        $categories = json_decode($categoriesJson, true) ?? [];
        
        $city = $request->input('city');
        
        // Строим запрос для получения новостей
        $newsQuery = News::where('is_active', true)
            ->where('is_archived', false)
            ->where('published_at', '<=', now())
            ->where(function ($query) {
                $query->whereNull('expired_at')
                    ->orWhere('expired_at', '>=', now());
            });
        
        // Фильтруем по городу, если указан (PostgreSQL jsonb)
        if ($city && $city !== 'Все') {
            $newsQuery->where(function ($q) use ($city) {
                $q->whereRaw("city @> ?", [json_encode([$city])])
                  ->orWhereRaw("city @> ?", [json_encode(['Все'])]);
            });
        }
        
        // Получаем все категории из активных новостей
        $newsWithCategories = $newsQuery->whereNotNull('category')
            ->pluck('category')
            ->toArray();
        
        // Собираем уникальные категории из JSON массивов
        $categoriesWithNews = [];
        foreach ($newsWithCategories as $categoryArray) {
            if (is_array($categoryArray)) {
                foreach ($categoryArray as $cat) {
                    if ($cat && $cat !== 'Все') {
                        $categoriesWithNews[$cat] = true;
                    }
                }
            } elseif (is_string($categoryArray) && $categoryArray !== '' && $categoryArray !== 'Все') {
                $categoriesWithNews[$categoryArray] = true;
            }
        }
        $categoriesWithNews = array_keys($categoriesWithNews);
        
        // Фильтруем категории - оставляем только те, у которых есть новости
        $filteredCategories = array_values(array_filter($categories, function ($category) use ($categoriesWithNews) {
            return in_array($category['name'] ?? '', $categoriesWithNews);
        }));

        return response()->json($filteredCategories, 200);
    }

    /**
     * @OA\Get(
     *     path="/admin/categories",
     *     summary="Получение всех категорий (для админки)",
     *     description="Возвращает все категории без фильтрации.",
     *     tags={"Categories"},
     *     @OA\Response(
     *         response=200,
     *         description="Список всех категорий"
     *     )
     * )
     */
    public function getAllCategories(): JsonResponse
    {
        $categoriesJson = Storage::disk('local')->get('categories.json');
        $categories = json_decode($categoriesJson, true) ?? [];

        return response()->json($categories, 200);
    }

    /**
     * @OA\Post(
     *     path="/categories",
     *     summary="Сохранение категорий",
     *     description="Сохраняет список категорий в файл categories.json.",
     *     tags={"Categories"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             type="array",
     *             @OA\Items(
     *                 type="object",
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="name", type="string", example="Категория 1")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Категории успешно сохранены",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Файл с городами успешно сохранён")
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Ошибка в данных"
     *     )
     * )
     */
    public function store(Request $request): JsonResponse
    {
        // Получаем массив категории напрямую из тела запроса
        $categories = $request->all();

        // Преобразуем массив категории в формат JSON
        $categoriesJson = json_encode($categories, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);

        // Сохраняем файл в директорию 'local'
        Storage::disk('local')->put('categories.json', $categoriesJson);

        // Возвращаем успешный ответ
        return response()->json(['message' => 'Файл с категориями успешно сохранён'], 201);
    }
}
