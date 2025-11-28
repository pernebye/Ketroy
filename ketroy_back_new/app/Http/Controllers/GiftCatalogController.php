<?php

namespace App\Http\Controllers;

use App\Models\GiftCatalog;
use App\Services\S3Service;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GiftCatalogController extends Controller
{
    protected S3Service $s3Service;

    public function __construct(S3Service $s3Service)
    {
        $this->s3Service = $s3Service;
    }

    /**
     * Получить список всех подарков из каталога
     */
    public function index(): JsonResponse
    {
        $gifts = GiftCatalog::where('is_active', true)
            ->orderBy('name')
            ->get();

        return response()->json($gifts);
    }

    /**
     * Получить все подарки (включая неактивные) для админки
     */
    public function all(Request $request): JsonResponse
    {
        // Проверяем, нужна ли пагинация
        $perPage = (int) $request->query('per_page');
        
        if ($perPage && $perPage > 0) {
            // Если явно запрашивается пагинация, используем её
            $gifts = GiftCatalog::orderBy('created_at', 'desc')->paginate($perPage);
        } else {
            // По умолчанию возвращаем все подарки без пагинации
            $gifts = GiftCatalog::orderBy('created_at', 'desc')->get();
        }

        return response()->json($gifts);
    }

    /**
     * Получить один подарок
     */
    public function show($id): JsonResponse
    {
        $gift = GiftCatalog::findOrFail($id);
        return response()->json($gift);
    }

    /**
     * Создать новый подарок в каталоге
     */
    public function store(Request $request): JsonResponse
    {
        \Log::info('[GiftCatalog Store] Creating new gift');
        \Log::info('[GiftCatalog Store] Name: ' . $request->name);
        \Log::info('[GiftCatalog Store] Image length: ' . ($request->image ? strlen($request->image) : 0));

        $request->validate([
            'name' => 'required|string|max:255',
            'image' => 'required|string', // Base64 изображение
            'description' => 'nullable|string',
        ]);

        try {
            // Загружаем изображение в S3
            \Log::info('[GiftCatalog Store] Uploading to S3...');
            $filePath = $this->s3Service->uploadBase64($request->image);
            \Log::info('[GiftCatalog Store] S3 URL: ' . $filePath);

            $gift = GiftCatalog::create([
                'name' => $request->name,
                'image' => $filePath,
                'description' => $request->description,
                'is_active' => true,
            ]);
            \Log::info('[GiftCatalog Store] Gift created with ID: ' . $gift->id);

            return response()->json([
                'message' => 'Подарок добавлен в каталог',
                'gift' => $gift
            ], 201);
        } catch (\Exception $e) {
            \Log::error('[GiftCatalog Store] Error: ' . $e->getMessage());
            \Log::error('[GiftCatalog Store] Trace: ' . $e->getTraceAsString());
            return response()->json([
                'message' => 'Ошибка создания подарка: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Обновить подарок в каталоге
     */
    public function update(Request $request, $id): JsonResponse
    {
        \Log::info('[GiftCatalog Update] Starting update for ID: ' . $id);
        \Log::info('[GiftCatalog Update] Request has image: ' . ($request->has('image') ? 'yes' : 'no'));
        
        if ($request->image) {
            \Log::info('[GiftCatalog Update] Image starts with data: ' . (str_starts_with($request->image, 'data:') ? 'yes' : 'no'));
            \Log::info('[GiftCatalog Update] Image length: ' . strlen($request->image));
        }

        $request->validate([
            'name' => 'required|string|max:255',
            'image' => 'nullable|string', // Base64 изображение (опционально)
            'description' => 'nullable|string',
            'is_active' => 'nullable|boolean',
        ]);

        $gift = GiftCatalog::findOrFail($id);
        \Log::info('[GiftCatalog Update] Found gift: ' . $gift->name);

        $updateData = [
            'name' => $request->name,
            'description' => $request->description,
        ];

        if ($request->has('is_active')) {
            $updateData['is_active'] = $request->is_active;
        }

        // Если передано новое изображение
        if ($request->image && str_starts_with($request->image, 'data:')) {
            \Log::info('[GiftCatalog Update] Uploading new image to S3...');
            try {
                $filePath = $this->s3Service->uploadBase64($request->image);
                $updateData['image'] = $filePath;
                \Log::info('[GiftCatalog Update] S3 upload success: ' . $filePath);
            } catch (\Exception $e) {
                \Log::error('[GiftCatalog Update] S3 upload failed: ' . $e->getMessage());
                return response()->json([
                    'message' => 'Ошибка загрузки изображения: ' . $e->getMessage()
                ], 500);
            }
        }

        $gift->update($updateData);
        \Log::info('[GiftCatalog Update] Gift updated successfully');

        return response()->json([
            'message' => 'Подарок обновлён',
            'gift' => $gift->fresh()
        ]);
    }

    /**
     * Удалить подарок из каталога (мягкое удаление - деактивация)
     */
    public function destroy($id): JsonResponse
    {
        $gift = GiftCatalog::findOrFail($id);
        
        // Проверяем, используется ли подарок в активных акциях
        $usedInPromotions = $gift->promotionGifts()
            ->whereHas('promotion', function ($q) {
                $q->where('is_archived', false);
            })
            ->exists();

        if ($usedInPromotions) {
            // Просто деактивируем
            $gift->update(['is_active' => false]);
            return response()->json([
                'message' => 'Подарок деактивирован (используется в активных акциях)'
            ]);
        }

        // Полностью удаляем если не используется
        $gift->delete();
        
        return response()->json([
            'message' => 'Подарок удалён из каталога'
        ]);
    }
}

