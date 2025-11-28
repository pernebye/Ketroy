<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Storage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CityController extends Controller
{
    /**
     * @OA\Get(
     *     path="/cities",
     *     summary="Получение списка городов",
     *     description="Возвращает список городов, которые хранятся в файле cities.json.",
     *     tags={"Cities"},
     *     @OA\Response(
     *         response=200,
     *         description="Список городов",
     *         @OA\JsonContent(
     *             type="array",
     *             @OA\Items(
     *                 type="object",
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="name", type="string", example="Город 1")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Файл с городами не найден"
     *     )
     * )
     */
    public function index(): JsonResponse
    {
        $cities = Storage::disk('local')->get('cities.json');

        return response()->json(json_decode($cities), 200);
    }

    /**
     * @OA\Post(
     *     path="/cities",
     *     summary="Сохранение городов",
     *     description="Сохраняет список городов в файл cities.json.",
     *     tags={"Cities"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             type="array",
     *             @OA\Items(
     *                 type="object",
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="name", type="string", example="Город 1"),
     *                 @OA\Property(property="phone", type="string", example="+77056789123")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Города успешно сохранены",
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
        // Получаем массив городов напрямую из тела запроса
        $cities = $request->all();

        // Преобразуем массив городов в формат JSON
        $citiesJson = json_encode($cities, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);

        // Сохраняем файл в директорию 'local'
        Storage::disk('local')->put('cities.json', $citiesJson);

        // Возвращаем успешный ответ
        return response()->json(['message' => 'Файл с городами успешно сохранён'], 201);
    }
}
