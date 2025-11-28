<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class CountryController extends Controller
{
    /**
     * @OA\Get(
     *     path="/countries",
     *     summary="Получение списка стран",
     *     description="Возвращает список стран, которые хранятся в файле countries.json.",
     *     tags={"Countries"},
     *     @OA\Response(
     *         response=200,
     *         description="Список стран",
     *         @OA\JsonContent(
     *             type="array",
     *             @OA\Items(
     *                 type="object",
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="name", type="string", example="Страна 1")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Файл со странами не найден"
     *     )
     * )
     */
    public function index(): JsonResponse
    {
        $countries = Storage::disk('local')->get('countries.json');

        return response()->json(json_decode($countries), 200);
    }

    /**
     * @OA\Post(
     *     path="/countries",
     *     summary="Сохранение стран",
     *     description="Сохраняет список стран в файл countries.json.",
     *     tags={"Countries"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             type="array",
     *             @OA\Items(
     *                 type="object",
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="name", type="string", example="Страна 1")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Страны успешно сохранены",
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
        $countries = $request->all();

        // Преобразуем массив городов в формат JSON
        $countriesJson = json_encode($countries, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);

        // Сохраняем файл в директорию 'local'
        Storage::disk('local')->put('countries.json', $countriesJson);

        // Возвращаем успешный ответ
        return response()->json(['message' => 'Файл с городами успешно сохранён'], 201);
    }
}
