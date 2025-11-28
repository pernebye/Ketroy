<?php

namespace App\Http\Controllers;

use App\Events\UserInteractionEvent;
use App\Jobs\UploadFileJob;
use App\Models\ActualGroup;
use App\Models\Story;
use App\Services\S3Service;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;


class StoryController extends Controller
{
    protected S3Service $s3Service;

    public function __construct(S3Service $s3Service)
    {
        $this->s3Service = $s3Service;
    }

    /**
     * @OA\Get(
     *     path="/stories",
     *     summary="Получение активных историй",
     *     description="Возвращает список активных историй с возможностью фильтрации по городу и актуальной группе.",
     *     tags={"Stories"},
     *     @OA\Parameter(
     *         name="city",
     *         in="query",
     *         required=false,
     *         description="Город для фильтрации",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Parameter(
     *         name="actual_group",
     *         in="query",
     *         required=false,
     *         description="Актуальная группа для фильтрации",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Список активных историй",
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
     *                     @OA\Property(property="actual_group", type="string"),
     *                     @OA\Property(property="type", type="string"),
     *                     @OA\Property(property="file_path", type="string"),
     *                     @OA\Property(property="is_active", type="boolean"),
     *                     @OA\Property(property="expired_at", type="string", format="date-time")
     *                 )
     *             ),
     *             @OA\Property(property="last_page", type="integer"),
     *             @OA\Property(property="per_page", type="integer"),
     *             @OA\Property(property="total", type="integer")
     *         )
     *     )
     * )
     */
    public function getActiveStories(Request $request): JsonResponse
    {
        $city = $request->input('city');
        
        $stories = Story::query()
            ->where('is_active', true)
            ->where(function ($query) {
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
            ->when($request->input('actual_group'), function ($query, $actual_group) {
                return $query->where('actual_group', $actual_group);
            })
            ->orderBy('sort_order', 'asc')
            ->orderBy('created_at', 'asc')->get();

        // Получаем группы с их порядком сортировки
        $actualGroups = ActualGroup::orderBy('sort_order')
            ->orderBy('id')
            ->get()
            ->keyBy('name');

        $storiesSorted = [];

        foreach ($stories as $story) {
            $group = $story->actual_group;

            if (!isset($storiesSorted[$group])) {
                $groupData = $actualGroups->get($group);
                $storiesSorted[$group] = [
                    'actual_group' => $group,
                    'stories' => [],
                    'sort_order' => $groupData?->sort_order ?? 999,
                    'is_welcome' => $groupData?->is_welcome ?? false,
                ];
            }

            $storiesSorted[$group]['stories'][] = $story->toArray();
        }

        // Сортируем группы по sort_order из actual_groups
        $result = array_values($storiesSorted);
        usort($result, function($a, $b) {
            return $a['sort_order'] <=> $b['sort_order'];
        });

        return response()->json($result);
    }

    /**
     * @OA\Post(
     *     path="/stories",
     *     summary="Создание новой истории",
     *     description="Создает новую историю.",
     *     tags={"Stories"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"name", "city", "actual_group", "type"},
     *             @OA\Property(property="name", type="string"),
     *             @OA\Property(property="description", type="string"),
     *             @OA\Property(property="city", type="string"),
     *             @OA\Property(property="actual_group", type="string"),
     *             @OA\Property(property="type", type="string", enum={"image", "video"}),
     *             @OA\Property(property="is_active", type="boolean"),
     *             @OA\Property(property="expired_at", type="string", format="date"),
     *             @OA\Property(property="file_path", type="string"),
     *             @OA\Property(property="file", type="string", format="binary")
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Сторис успешно создан",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Сторис успешно создан"),
     *             @OA\Property(property="story", type="object",
     *                 @OA\Property(property="id", type="integer"),
     *                 @OA\Property(property="name", type="string"),
     *                 @OA\Property(property="description", type="string"),
     *                 @OA\Property(property="city", type="string"),
     *                 @OA\Property(property="actual_group", type="string"),
     *                 @OA\Property(property="type", type="string"),
     *                 @OA\Property(property="file_path", type="string"),
     *                 @OA\Property(property="is_active", type="boolean"),
     *                 @OA\Property(property="expired_at", type="string", format="date-time")
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
            'name' => 'nullable|string|max:255',
            'cities' => 'sometimes|array',
            'cities.*' => 'string',
            'actual_group' => 'required|string|max:255',
            'type' => 'required|string|in:image,video',
            'is_active' => 'boolean',
            'file_path' => 'required|string',
        ]);

        // Проверяем, является ли file_path уже URL или base64
        $filePath = $request->file_path;
        if ($filePath && !str_starts_with($filePath, 'http')) {
            $filePath = $this->s3Service->uploadBase64($filePath);
        }

        $story = Story::create([
            'name' => $request->name ?? '',
            'cities' => $request->cities ?? ['Все'],
            'actual_group' => $request->actual_group,
            'type' => $request->type,
            'file_path' => $filePath,
            'is_active' => $request->is_active ?? true,
        ]);

        return response()->json([
            'message' => 'Сторис создана. Файлы загружаются.',
            'story' => $story
        ], 201);
    }

    /**
     * @OA\Get(
     *     path="/stories/{id}",
     *     summary="Получение истории по ID",
     *     description="Возвращает историю по указанному ID.",
     *     tags={"Stories"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="ID истории",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="История найдена",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="id", type="integer"),
     *             @OA\Property(property="name", type="string"),
     *             @OA\Property(property="description", type="string"),
     *             @OA\Property(property="city", type="string"),
     *             @OA\Property(property="actual_group", type="string"),
     *             @OA\Property(property="type", type="string"),
     *             @OA\Property(property="file_path", type="string"),
     *             @OA\Property(property="is_active", type="boolean"),
     *             @OA\Property(property="expired_at", type="string", format="date-time")
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="История не найдена"
     *     )
     * )
     */
    public function show($id): JsonResponse
    {
        $story = Story::findOrFail($id);
        event(new UserInteractionEvent("story", ['id' => $id, 'name' => $story->name], null));
        return response()->json($story);
    }

    /**
     * @OA\Put(
     *     path="/stories/{id}",
     *     summary="Обновление истории",
     *     description="Обновляет историю по указанному ID.",
     *     tags={"Stories"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="ID истории",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"name", "city", "actual_group", "type"},
     *             @OA\Property(property="name", type="string"),
     *             @OA\Property(property="description", type="string"),
     *             @OA\Property(property="city", type="string"),
     *             @OA\Property(property="actual_group", type="string"),
     *             @OA\Property(property="type", type="string", enum={"image", "video"}),
     *             @OA\Property(property="is_active", type="boolean"),
     *             @OA\Property(property="expired_at", type="string", format="date"),
     *             @OA\Property(property="file_path", type="string"),
     *             @OA\Property(property="file", type="string", format="binary")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Сторис успешно изменён",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Сторис успешно изменён"),
     *             @OA\Property(property="story", type="object",
     *                 @OA\Property(property="id", type="integer"),
     *                 @OA\Property(property="name", type="string"),
     *                 @OA\Property(property="description", type="string"),
     *                 @OA\Property(property="city", type="string"),
     *                 @OA\Property(property="actual_group", type="string"),
     *                 @OA\Property(property="type", type="string"),
     *                 @OA\Property(property="file_path", type="string"),
     *                 @OA\Property(property="is_active", type="boolean"),
     *                 @OA\Property(property="expired_at", type="string", format="date-time")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="История не найдена"
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Ошибка валидации"
     *     )
     * )
     */
    public function update(Request $request, $id): JsonResponse
    {
        $story = Story::findOrFail($id);

        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'cities' => 'sometimes|array',
            'cities.*' => 'string',
            'actual_group' => 'required|string|max:255',
            'type' => 'required|string|in:image,video',
            'is_active' => 'boolean',
            'expired_at' => 'nullable|date',
            'file' => 'sometimes|string',
            'cover' => 'sometimes|string',
        ]);

        // Обработка файла
        $filePath = $story->file_path; // По умолчанию сохраняем старый путь
        if ($request->file) {
            if (str_starts_with($request->file, "https://")) {
                $filePath = $request->file;
            } else {
                // Удаляем старый файл только если он существует
                if ($story->file_path) {
                    Storage::disk('s3')->delete($story->file_path);
                }
                $filePath = $this->s3Service->uploadBase64($request->file);
            }
        }

        // Обработка обложки
        $coverPath = $story->cover_path; // По умолчанию сохраняем старый путь
        if ($request->cover) {
            if (str_starts_with($request->cover, "https://")) {
                $coverPath = $request->cover;
            } else {
                // Удаляем старый файл только если он существует
                if ($story->cover_path) {
                    Storage::disk('s3')->delete($story->cover_path);
                }
                $coverPath = $this->s3Service->uploadBase64($request->cover);
            }
        }

        $story = Story::where('id', $id)->update([
            'name' => $request->name,
            'description' => $request->description,
            'cities' => $request->cities ?? ['Все'],
            'actual_group' => $request->actual_group,
            'type' => $request->type,
            'file_path' => $filePath, // URL загруженного файла
            'cover_path' => $coverPath ?? null, // URL загруженного файла
            'is_active' => $request->is_active ?? true,
            'expired_at' => $request->expired_at,
        ]);

        return response()->json([
            'message' => 'Сторис успешно изменен',
            'story' => $story
        ], 200);
    }

    /**
     * @OA\Delete(
     *     path="/stories/{id}",
     *     summary="Удаление истории",
     *     description="Удаляет историю по указанному ID.",
     *     tags={"Stories"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="ID истории",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Сторис успешно удалён",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Сторис успешно удалён")
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="История не найдена"
     *     )
     * )
     */
    public function destroy($id): JsonResponse
    {
        $story = Story::findOrFail($id);
        Storage::disk('s3')->delete($story->file_path); // Удаляем старый файл
        if ($story->cover_path != null) {
            Storage::disk('s3')->delete($story->cover_path); // Удаляем старый файл
        }
        $story->delete();

        return response()->json([
            'message' => 'Сторис успешно удалён'
        ], 200);
    }

    /**
     * @OA\Post(
     *     path="/admin/stories/bulk-delete",
     *     summary="Массовое удаление историй",
     *     description="Удаляет несколько историй по указанным ID с удалением файлов из хранилища.",
     *     tags={"Stories"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"ids"},
     *             @OA\Property(property="ids", type="array", @OA\Items(type="integer"))
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Истории успешно удалены",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Истории успешно удалены"),
     *             @OA\Property(property="deleted_count", type="integer")
     *         )
     *     )
     * )
     */
    public function bulkDestroy(Request $request): JsonResponse
    {
        $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'integer|exists:stories,id'
        ]);

        $ids = $request->input('ids');
        $deletedCount = 0;

        foreach ($ids as $id) {
            $story = Story::find($id);
            if ($story) {
                // Удаляем файлы из S3
                if ($story->file_path) {
                    Storage::disk('s3')->delete($story->file_path);
                }
                if ($story->cover_path) {
                    Storage::disk('s3')->delete($story->cover_path);
                }
                $story->delete();
                $deletedCount++;
            }
        }

        return response()->json([
            'message' => 'Истории успешно удалены',
            'deleted_count' => $deletedCount
        ], 200);
    }

    /**
     * @OA\Get(
     *     path="/admin/stories",
     *     summary="Получение активных историй",
     *     description="Возвращает список активных историй с возможностью фильтрации по городу и актуальной группе.",
     *     tags={"Stories"},
     *     @OA\Parameter(
     *         name="city",
     *         in="query",
     *         required=false,
     *         description="Город для фильтрации",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Parameter(
     *         name="actual_group",
     *         in="query",
     *         required=false,
     *         description="Актуальная группа для фильтрации",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Список активных историй",
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
     *                     @OA\Property(property="actual_group", type="string"),
     *                     @OA\Property(property="type", type="string"),
     *                     @OA\Property(property="file_path", type="string"),
     *                     @OA\Property(property="is_active", type="boolean"),
     *                     @OA\Property(property="expired_at", type="string", format="date-time")
     *                 )
     *             ),
     *             @OA\Property(property="last_page", type="integer"),
     *             @OA\Property(property="per_page", type="integer"),
     *             @OA\Property(property="total", type="integer")
     *         )
     *     )
     * )
     */
    public function getAllStories(Request $request): JsonResponse
    {
        $city = $request->input('city');
        
        $stories = Story::query()
            ->when($city, function ($query) use ($city) {
                return $query->whereJsonContains('cities', $city);
            })
            ->when($request->input('actual_group'), function ($query, $actual_group) {
                return $query->where('actual_group', $actual_group);
            })
            ->orderBy('sort_order', 'asc')
            ->orderBy('created_at', 'asc')->get();

        return response()->json($stories);
    }

    /**
     * @OA\Post(
     *     path="/admin/stories/reorder",
     *     summary="Изменение порядка историй",
     *     description="Обновляет порядок отображения историй внутри группы",
     *     tags={"Stories"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"stories"},
     *             @OA\Property(
     *                 property="stories",
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
     *             @OA\Property(property="message", type="string", example="Порядок историй обновлён")
     *         )
     *     )
     * )
     */
    public function reorder(Request $request): JsonResponse
    {
        $request->validate([
            'stories' => 'required|array',
            'stories.*.id' => 'required|integer|exists:stories,id',
            'stories.*.sort_order' => 'required|integer|min:0'
        ]);

        foreach ($request->stories as $storyData) {
            Story::where('id', $storyData['id'])
                ->update(['sort_order' => $storyData['sort_order']]);
        }

        return response()->json([
            'message' => 'Порядок историй обновлён'
        ], 200);
    }
}
