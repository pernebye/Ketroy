<?php

namespace App\Http\Controllers;

use App\Models\ActualGroup;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ActualController extends Controller
{
    /**
     * @OA\Get(
     *     path="/actuals",
     *     summary="Получить все актуальные группы",
     *     tags={"Actuals"},
     *     @OA\Response(
     *         response=200,
     *         description="Список актуальных групп",
     *         @OA\JsonContent(
     *             type="array",
     *             @OA\Items(
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="name", type="string", example="Ketroy"),
     *                 @OA\Property(property="image", type="string", nullable=true),
     *                 @OA\Property(property="is_welcome", type="boolean", example=false),
     *                 @OA\Property(property="is_system", type="boolean", example=false),
     *                 @OA\Property(property="sort_order", type="integer", example=0)
     *             )
     *         )
     *     )
     * )
     */
    public function index(): JsonResponse
    {
        $groups = ActualGroup::orderBy('sort_order')
            ->orderBy('id')
            ->get();

        return response()->json($groups, 200);
    }


    /**
     * @OA\Post(
     *     path="/actuals",
     *     summary="Синхронизировать актуальные группы",
     *     description="Обновляет список групп. Создаёт новые, обновляет существующие. Системные группы не удаляются.",
     *     tags={"Actuals"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             type="array",
     *             @OA\Items(
     *                 @OA\Property(property="name", type="string", example="Ketroy"),
     *                 @OA\Property(property="image", type="string", nullable=true),
     *                 @OA\Property(property="is_welcome", type="boolean", example=false)
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Группы успешно синхронизированы",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Группы успешно синхронизированы"),
     *             @OA\Property(property="groups", type="array", @OA\Items(type="object"))
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Ошибка в запросе"
     *     )
     * )
     */
    public function store(Request $request): JsonResponse
    {
        $actualsData = $request->all();
        
        // Получаем имена из входящих данных
        $incomingNames = collect($actualsData)->pluck('name')->filter()->toArray();
        
        // Проверяем, есть ли во входящих данных группа с is_welcome = true
        $welcomeGroupName = null;
        foreach ($actualsData as $actualData) {
            $isWelcome = filter_var($actualData['is_welcome'] ?? false, FILTER_VALIDATE_BOOLEAN);
            if ($isWelcome) {
                $welcomeGroupName = $actualData['name'] ?? null;
                break;
            }
        }
        
        // Если есть новая приветственная группа, сбрасываем is_welcome у всех остальных
        if ($welcomeGroupName) {
            ActualGroup::where('name', '!=', $welcomeGroupName)
                ->update(['is_welcome' => false]);
        }
        
        // Обновляем или создаём группы
        $sortOrder = 0;
        foreach ($actualsData as $actualData) {
            if (empty($actualData['name'])) continue;
            
            $name = $actualData['name'];
            $isWelcome = filter_var($actualData['is_welcome'] ?? false, FILTER_VALIDATE_BOOLEAN);
            
            ActualGroup::updateOrCreate(
                ['name' => $name],
                [
                    'image' => $actualData['image'] ?? null,
                    'is_welcome' => $isWelcome,
                    'sort_order' => $sortOrder++,
                ]
            );
        }
        
        // Удаляем группы, которых нет во входящих данных (кроме системных)
        ActualGroup::whereNotIn('name', $incomingNames)
            ->where('is_system', false)
            ->delete();
        
        $groups = ActualGroup::orderBy('sort_order')
            ->orderBy('id')
            ->get();

        return response()->json([
            'message' => 'Группы успешно синхронизированы',
            'groups' => $groups
        ], 200);
    }

    /**
     * @OA\Get(
     *     path="/actuals/{id}",
     *     summary="Получить группу по ID",
     *     tags={"Actuals"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Данные группы"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Группа не найдена"
     *     )
     * )
     */
    public function show(int $id): JsonResponse
    {
        $group = ActualGroup::find($id);
        
        if (!$group) {
            return response()->json(['error' => 'Группа не найдена'], 404);
        }

        return response()->json($group, 200);
    }

    /**
     * @OA\Delete(
     *     path="/actuals/{id}",
     *     summary="Удалить группу",
     *     tags={"Actuals"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Группа удалена"
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="Системную группу нельзя удалить"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Группа не найдена"
     *     )
     * )
     */
    public function destroy(int $id): JsonResponse
    {
        $group = ActualGroup::find($id);
        
        if (!$group) {
            return response()->json(['error' => 'Группа не найдена'], 404);
        }
        
        if ($group->is_system) {
            return response()->json(['error' => 'Системную группу нельзя удалить'], 403);
        }

        $group->delete();

        return response()->json(['message' => 'Группа удалена'], 200);
    }

    /**
     * @OA\Post(
     *     path="/admin/actuals/reorder",
     *     summary="Изменение порядка групп",
     *     description="Обновляет порядок отображения групп историй",
     *     tags={"Actuals"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"groups"},
     *             @OA\Property(
     *                 property="groups",
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
     *         description="Порядок успешно обновлён",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Порядок групп обновлён"),
     *             @OA\Property(property="groups", type="array", @OA\Items(type="object"))
     *         )
     *     )
     * )
     */
    public function reorder(Request $request): JsonResponse
    {
        $request->validate([
            'groups' => 'required|array',
            'groups.*.id' => 'required|integer|exists:actual_groups,id',
            'groups.*.sort_order' => 'required|integer|min:0'
        ]);

        foreach ($request->groups as $groupData) {
            ActualGroup::where('id', $groupData['id'])
                ->update(['sort_order' => $groupData['sort_order']]);
        }

        $groups = ActualGroup::orderBy('sort_order')
            ->orderBy('id')
            ->get();

        return response()->json([
            'message' => 'Порядок групп обновлён',
            'groups' => $groups
        ], 200);
    }
}
