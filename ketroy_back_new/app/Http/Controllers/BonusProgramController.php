<?php

namespace App\Http\Controllers;

use App\Models\BonusProgram;
use Illuminate\Http\Request;

namespace App\Http\Controllers;

use App\Models\BonusProgram;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Storage;

class BonusProgramController extends Controller
{
    /**
     * @OA\Get(
     *     path="/api/bonus-programs",
     *     summary="Получение всех бонусных программ",
     *     tags={"Bonus Programs"},
     *     @OA\Response(response=200, description="Список бонусных программ")
     * )
     */
    public function index()
    {
        return response()->json(BonusProgram::all());
    }

    /**
     * @OA\Post(
     *     path="/api/bonus-programs",
     *     summary="Создание бонусной программы",
     *     tags={"Bonus Programs"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"title", "description"},
     *             @OA\Property(property="title", type="string", example="Весенняя акция"),
     *             @OA\Property(property="description", type="string", example="Скидки до 50%"),
     *             @OA\Property(property="image", type="string", example="image.jpg"),
     *             @OA\Property(property="published_at", type="string", format="date-time", example="2025-04-01 12:00:00")
     *         )
     *     ),
     *     @OA\Response(response=201, description="Бонусная программа создана")
     * )
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'image' => 'nullable|image|max:2048',
            'published_at' => 'nullable|date'
        ]);

        if ($request->hasFile('image')) {
            $data['image'] = $request->file('image')->store('bonus_images', 'public');
        }

        $bonusProgram = BonusProgram::create($data);
        return response()->json($bonusProgram, Response::HTTP_CREATED);
    }

    /**
     * @OA\Get(
     *     path="/api/bonus-programs/{id}",
     *     summary="Получение одной бонусной программы",
     *     tags={"Bonus Programs"},
     *     @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\Response(response=200, description="Бонусная программа найдена"),
     *     @OA\Response(response=404, description="Бонусная программа не найдена")
     * )
     */
    public function show($id)
    {
        $bonusProgram = BonusProgram::findOrFail($id);
        return response()->json($bonusProgram);
    }

    /**
     * @OA\Put(
     *     path="/api/bonus-programs/{id}",
     *     summary="Обновление бонусной программы",
     *     tags={"Bonus Programs"},
     *     @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"title", "description"},
     *             @OA\Property(property="title", type="string"),
     *             @OA\Property(property="description", type="string"),
     *             @OA\Property(property="image", type="string"),
     *             @OA\Property(property="published_at", type="string", format="date-time")
     *         )
     *     ),
     *     @OA\Response(response=200, description="Обновлено"),
     *     @OA\Response(response=404, description="Не найдено")
     * )
     */
    public function update(Request $request, $id)
    {
        $bonusProgram = BonusProgram::findOrFail($id);

        $data = $request->validate([
            'title' => 'sometimes|string|max:255',
            'description' => 'sometimes|string',
            'image' => 'nullable|image|max:2048',
            'published_at' => 'nullable|date'
        ]);

        if ($request->hasFile('image')) {
            if ($bonusProgram->image) {
                Storage::disk('s3')->delete($bonusProgram->image);
            }
            $data['image'] = $request->file('image')->store('bonus_images', 'public');
        }

        $bonusProgram->update($data);
        return response()->json($bonusProgram);
    }

    /**
     * @OA\Delete(
     *     path="/api/bonus-programs/{id}",
     *     summary="Удаление бонусной программы",
     *     tags={"Bonus Programs"},
     *     @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\Response(response=204, description="Удалено"),
     *     @OA\Response(response=404, description="Не найдено")
     * )
     */
    public function destroy($id)
    {
        $bonusProgram = BonusProgram::findOrFail($id);

        if ($bonusProgram->image) {
            Storage::disk('s3')->delete($bonusProgram->image);
        }

        $bonusProgram->delete();
        return response()->json(null, Response::HTTP_NO_CONTENT);
    }
}
