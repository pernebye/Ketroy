<?php

namespace App\Http\Controllers;

use App\Services\S3Service;
use App\Services\VideoToGifService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class UploadController extends Controller
{
    protected S3Service $s3Service;
    protected VideoToGifService $videoService;

    public function __construct(S3Service $s3Service, VideoToGifService $videoService)
    {
        $this->s3Service = $s3Service;
        $this->videoService = $videoService;
    }

    /**
     * @OA\Post(
     *     path="/admin/upload",
     *     summary="Загрузка файлов на сервер",
     *     description="Загружает один или несколько файлов. Видео автоматически конвертируется в GIF.",
     *     tags={"Media"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\MediaType(
     *             mediaType="multipart/form-data",
     *             @OA\Schema(
     *                 @OA\Property(
     *                     property="files",
     *                     type="array",
     *                     @OA\Items(type="string", format="binary"),
     *                     description="Файлы для загрузки"
     *                 ),
     *                 @OA\Property(
     *                     property="file",
     *                     type="string",
     *                     format="binary",
     *                     description="Один файл для загрузки"
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Файлы успешно загружены",
     *         @OA\JsonContent(
     *             type="array",
     *             @OA\Items(type="string")
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Ошибка загрузки"
     *     )
     * )
     */
    public function upload(Request $request): JsonResponse
    {
        $urls = [];
        
        // Обрабатываем массив файлов
        if ($request->hasFile('files')) {
            $files = $request->file('files');
            if (!is_array($files)) {
                $files = [$files];
            }
            
            foreach ($files as $file) {
                $url = $this->processFile($file);
                if ($url) {
                    $urls[] = $url;
                }
            }
        }
        
        // Обрабатываем один файл
        if ($request->hasFile('file')) {
            $url = $this->processFile($request->file('file'));
            if ($url) {
                $urls[] = $url;
            }
        }
        
        if (empty($urls)) {
            return response()->json(['error' => 'Не удалось загрузить файлы'], 400);
        }
        
        return response()->json($urls);
    }

    /**
     * Обработка одного файла
     */
    protected function processFile($file): ?string
    {
        $mimeType = $file->getMimeType();
        $extension = strtolower($file->getClientOriginalExtension());
        
        // Если это видео - конвертируем в GIF
        if ($this->videoService->isSupported($file)) {
            try {
                $result = $this->videoService->convertToGif($file);
                return $result['url'] ?? null;
            } catch (\Exception $e) {
                \Log::error('[UploadController] Video conversion failed: ' . $e->getMessage());
                return null;
            }
        }
        
        // Если это изображение - загружаем напрямую
        if (str_starts_with($mimeType, 'image/')) {
            return $this->uploadImage($file);
        }
        
        return null;
    }

    /**
     * Загрузка изображения
     */
    protected function uploadImage($file): string
    {
        $extension = $file->getClientOriginalExtension() ?: 'jpg';
        $mimeType = $file->getMimeType();
        $filename = 'images/' . Str::uuid() . '.' . $extension;
        
        // Используем публичные методы S3Service
        $this->s3Service->uploadToS3WithAcl($filename, file_get_contents($file->getRealPath()), $mimeType);
        return $this->s3Service->getPublicUrl($filename);
    }
}

