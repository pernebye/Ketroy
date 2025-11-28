<?php

namespace App\Http\Controllers;

use App\Services\VideoToGifService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VideoController extends Controller
{
    protected VideoToGifService $videoService;

    public function __construct(VideoToGifService $videoService)
    {
        $this->videoService = $videoService;
    }

    /**
     * @OA\Post(
     *     path="/admin/video-to-gif",
     *     summary="Конвертация видео в GIF",
     *     description="Конвертирует загруженное видео в GIF формат. Поддерживает MOV, MP4, HEVC и другие форматы. Максимальная длительность: 15 секунд.",
     *     tags={"Media"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\MediaType(
     *             mediaType="multipart/form-data",
     *             @OA\Schema(
     *                 @OA\Property(
     *                     property="video",
     *                     type="string",
     *                     format="binary",
     *                     description="Видео файл (MOV, MP4, HEVC, AVI, WebM, MKV)"
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="GIF успешно создан",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="url", type="string", example="https://storage.example.com/gifs/uuid.gif"),
     *             @OA\Property(property="duration", type="number", example=5.5),
     *             @OA\Property(property="original_size", type="string", example="1920x1080"),
     *             @OA\Property(property="gif_size", type="string", example="480x270"),
     *             @OA\Property(property="file_size", type="integer", example=1024000)
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Ошибка валидации или конвертации",
     *         @OA\JsonContent(
     *             @OA\Property(property="error", type="string", example="Видео слишком длинное")
     *         )
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Неподдерживаемый формат"
     *     )
     * )
     */
    public function convertToGif(Request $request): JsonResponse
    {
        // Логируем что приходит в запросе
        \Log::info('[VideoController] Incoming request', [
            'has_file' => $request->hasFile('video'),
            'all_files' => array_keys($request->allFiles()),
            'content_type' => $request->header('Content-Type'),
            'all_inputs' => array_keys($request->all()),
        ]);

        // Валидация
        $request->validate([
            'video' => [
                'required',
                'file',
                'max:102400', // 100MB максимум
            ],
        ], [
            'video.required' => 'Видео файл обязателен',
            'video.file' => 'Необходимо загрузить файл',
            'video.max' => 'Максимальный размер файла: 100MB',
        ]);

        $file = $request->file('video');

        // Проверяем формат
        if (!$this->videoService->isSupported($file)) {
            return response()->json([
                'error' => 'Неподдерживаемый формат видео. Поддерживаются: ' . 
                           implode(', ', $this->videoService->getSupportedFormats()),
            ], 422);
        }

        try {
            // Проверяем длительность
            if (!$this->videoService->isDurationValid($file->getPathname())) {
                $duration = $this->videoService->getVideoDuration($file->getPathname());
                $maxDuration = $this->videoService->getMaxDuration();
                
                return response()->json([
                    'error' => "Видео слишком длинное ({$duration} сек). Максимум: {$maxDuration} секунд",
                    'duration' => $duration,
                    'max_duration' => $maxDuration,
                ], 400);
            }

            // Конвертируем
            $result = $this->videoService->convertToGif($file);

            return response()->json($result);

        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'error' => $e->getMessage(),
            ], 400);
        } catch (\Exception $e) {
            \Log::error('[VideoController] Conversion failed: ' . $e->getMessage());
            
            return response()->json([
                'error' => 'Ошибка конвертации видео: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * @OA\Post(
     *     path="/admin/video-to-gif/base64",
     *     summary="Конвертация base64 видео в GIF",
     *     description="Конвертирует видео из base64 строки в GIF формат",
     *     tags={"Media"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             @OA\Property(property="video", type="string", description="Base64 encoded video")
     *         )
     *     ),
     *     @OA\Response(response=200, description="GIF успешно создан"),
     *     @OA\Response(response=400, description="Ошибка конвертации")
     * )
     */
    public function convertBase64ToGif(Request $request): JsonResponse
    {
        $request->validate([
            'video' => 'required|string',
        ]);

        try {
            $result = $this->videoService->convertBase64ToGif($request->video);
            return response()->json($result);

        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'error' => $e->getMessage(),
            ], 400);
        } catch (\Exception $e) {
            \Log::error('[VideoController] Base64 conversion failed: ' . $e->getMessage());
            
            return response()->json([
                'error' => 'Ошибка конвертации видео: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * @OA\Get(
     *     path="/admin/video-to-gif/info",
     *     summary="Информация о поддерживаемых форматах",
     *     tags={"Media"},
     *     @OA\Response(
     *         response=200,
     *         description="Информация о конвертере",
     *         @OA\JsonContent(
     *             @OA\Property(property="max_duration", type="integer", example=15),
     *             @OA\Property(property="supported_formats", type="array", @OA\Items(type="string")),
     *             @OA\Property(property="max_file_size_mb", type="integer", example=100),
     *             @OA\Property(property="ffmpeg_installed", type="boolean", example=true),
     *             @OA\Property(property="ffmpeg_path", type="string", example="/usr/bin/ffmpeg")
     *         )
     *     )
     * )
     */
    public function info(): JsonResponse
    {
        $isInstalled = $this->videoService->isFFMpegInstalled();
        
        return response()->json([
            'max_duration' => $this->videoService->getMaxDuration(),
            'supported_formats' => $this->videoService->getSupportedFormats(),
            'max_file_size_mb' => 100,
            'ffmpeg_installed' => $isInstalled,
            'ffmpeg_path' => $isInstalled ? $this->videoService->getFFMpegPath() : null,
            'message' => $isInstalled 
                ? 'Конвертер готов к работе' 
                : 'FFMpeg не установлен! Установите FFMpeg для конвертации видео в GIF.',
        ]);
    }
}

