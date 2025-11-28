<?php

namespace App\Http\Controllers;

use App\Models\Shop;
use App\Services\S3Service;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShopController extends Controller
{

    protected S3Service $s3Service;

    public function __construct(S3Service $s3Service)
    {
        $this->s3Service = $s3Service;
    }
    /**
     * @OA\Get(
     *     path="/shops",
     *     summary="Получение списка магазинов",
     *     description="Возвращает список всех магазинов.",
     *     tags={"Shops"},
     *     @OA\Response(
     *         response=200,
     *         description="Список магазинов",
     *         @OA\JsonContent(
     *             type="array",
     *             @OA\Items(
     *                 type="object",
     *                 @OA\Property(property="id", type="integer"),
     *                 @OA\Property(property="name", type="string"),
     *                 @OA\Property(property="description", type="string"),
     *                 @OA\Property(property="city", type="string"),
     *                 @OA\Property(property="two_gis_address", type="string"),
     *                 @OA\Property(property="address", type="string"),
     *                 @OA\Property(property="opening_hours", type="string")
     *             )
     *         )
     *     )
     * )
     */
    public function index(Request $request): JsonResponse
    {
        $shops = Shop::query()
            ->where('is_active', true)
            ->when($request->input('city'), function ($query, $city) {
                return $query->where('city', $city);
            })->get();

        // Форматируем инстаграм ссылки
        $shops = $shops->map(function ($shop) {
            if ($shop->instagram) {
                $shop->instagram = $this->formatInstagramUrl($shop->instagram);
            }
            return $shop;
        });

        return response()->json($shops);
    }

    /**
     * @OA\Post(
     *     path="/shops",
     *     summary="Создание магазина",
     *     description="Создает новый магазин.",
     *     tags={"Shops"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"name", "city", "opening_hours"},
     *             @OA\Property(property="name", type="string"),
     *             @OA\Property(property="description", type="string"),
     *             @OA\Property(property="city", type="string"),
     *             @OA\Property(property="two_gis_address", type="string"),
     *             @OA\Property(property="address", type="string"),
     *             @OA\Property(property="opening_hours", type="string")
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Магазин успешно создан",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Магазин успешно создан"),
     *             @OA\Property(property="shop", type="object",
     *                 @OA\Property(property="id", type="integer"),
     *                 @OA\Property(property="name", type="string"),
     *                 @OA\Property(property="description", type="string"),
     *                 @OA\Property(property="city", type="string"),
     *                 @OA\Property(property="two_gis_address", type="string"),
     *                 @OA\Property(property="address", type="string"),
     *                 @OA\Property(property="opening_hours", type="string")
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
        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'city' => 'required|string|max:255',
            'opening_hours' => 'required|string|max:255',
            'two_gis_address' => 'nullable|string',
            'file' => 'sometimes|string',
            'file_path' => 'sometimes|string',
            'address' => 'nullable|string',
            'instagram' => 'nullable|string',
            'whatsapp' => 'nullable|string',
            'is_active' => 'required|boolean',
        ]);

        $filePath = null;
        if (str_starts_with($request->file, "https://")) {
            $filePath = $request->file;
        } elseif (!empty($request->file)) {
            $filePath = $this->s3Service->uploadBase64($request->file);
        }

        $shop = Shop::create([
            'name' => $request->name,
            'description' => $request->description,
            'city' => $request->city,
            'two_gis_address' => $request->two_gis_address,
            'opening_hours' => $request->opening_hours,
            'file_path' => $filePath,
            'address' => $request->address,
            'instagram' => $request->instagram,
            'whatsapp' => $request->whatsapp,
            'is_active' => $request->is_active
        ]);

        return response()->json([
            'message' => 'Магазин успешно создан',
            'shop' => $shop
        ], 201);
    }

    /**
     * @OA\Get(
     *     path="/shops/{id}",
     *     summary="Получение магазина",
     *     description="Возвращает магазин по указанному идентификатору.",
     *     tags={"Shops"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="ID магазина",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Детали магазина",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="id", type="integer"),
     *             @OA\Property(property="name", type="string"),
     *             @OA\Property(property="description", type="string"),
     *             @OA\Property(property="city", type="string"),
     *             @OA\Property(property="two_gis_address", type="string"),
     *             @OA\Property(property="address", type="string"),
     *             @OA\Property(property="opening_hours", type="string")
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Магазин не найден"
     *     )
     * )
     */
    public function show($id): JsonResponse
    {
        $shop = Shop::findOrFail($id);
        
        // Форматируем инстаграм ссылку
        if ($shop->instagram) {
            $shop->instagram = $this->formatInstagramUrl($shop->instagram);
        }
        
        return response()->json($shop);
    }

    /**
     * @OA\Put(
     *     path="/shops/{id}",
     *     summary="Обновление магазина",
     *     description="Обновляет существующий магазин.",
     *     tags={"Shops"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="ID магазина",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"name", "city", "opening_hours"},
     *             @OA\Property(property="name", type="string"),
     *             @OA\Property(property="description", type="string"),
     *             @OA\Property(property="city", type="string"),
     *             @OA\Property(property="two_gis_address", type="string"),
     *             @OA\Property(property="address", type="string"),
     *             @OA\Property(property="opening_hours", type="string")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Магазин успешно обновлен",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Магазин успешно обновлён"),
     *             @OA\Property(property="shop", type="object",
     *                 @OA\Property(property="id", type="integer"),
     *                 @OA\Property(property="name", type="string"),
     *                 @OA\Property(property="description", type="string"),
     *                 @OA\Property(property="city", type="string"),
     *                 @OA\Property(property="two_gis_address", type="string"),
     *                 @OA\Property(property="address", type="string"),
     *                 @OA\Property(property="opening_hours", type="string")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Магазин не найден"
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Ошибка валидации"
     *     )
     * )
     */
    public function update(Request $request, $id): JsonResponse
    {
        $shop = Shop::findOrFail($id);
        $filePath = null;

        $request->validate([
            'is_active' => 'required|boolean',
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'city' => 'required|string|max:255',
            'two_gis_address' => 'nullable|string',
            'opening_hours' => 'required|string|max:255',
            'file' => 'sometimes|string',
            'address' => 'nullable|string',
            'instagram' => 'nullable|string',
            'whatsapp' => 'nullable|string',
        ]);

        if (str_starts_with($request->file, "https://")) {
            $filePath = $request->file;
        } else {
            $filePath = $this->s3Service->uploadBase64($request->file);
        }

        $shop->update([
            'is_active' => $request->is_active,
            'name' => $request->name,
            'description' => $request->description,
            'city' => $request->city,
            'two_gis_address' => $request->two_gis_address,
            'opening_hours' => $request->opening_hours,
            'file_path' => $filePath,
            'address' => $request->address,
            'instagram' => $request->instagram,
            'whatsapp' => $request->whatsapp
        ]);

        return response()->json([
            'message' => 'Магазин успешно обновлён',
            'shop' => $shop
        ], 200);
    }

    /**
     * @OA\Delete(
     *     path="/shops/{id}",
     *     summary="Удаление магазина",
     *     description="Удаляет магазин по указанному идентификатору.",
     *     tags={"Shops"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="ID магазина",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=204,
     *         description="Магазин успешно удален"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Магазин не найден"
     *     )
     * )
     */
    public function destroy($id): JsonResponse
    {
        $shop = Shop::findOrFail($id);
        $shop->delete();

        return response()->json([
            'message' => 'Магазин успешно удалён'
        ], 200);
    }

    /**
     * Форматирует Instagram ссылку из никнейма
     * Если передан просто никнейм (без http), преобразует его в полную ссылку
     */
    private function formatInstagramUrl($instagram): string
    {
        if (!$instagram) {
            return '';
        }

        // Если уже полная ссылка, возвращаем как есть
        if (str_starts_with($instagram, 'http')) {
            return $instagram;
        }

        // Удаляем @ если есть
        $username = str_replace('@', '', $instagram);

        // Преобразуем в полную ссылку
        return "https://instagram.com/{$username}";
    }
}
