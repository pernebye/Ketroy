<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;

class VideoToGifService
{
    protected S3Service $s3Service;
    
    // Максимальная длительность видео (15 секунд)
    protected int $maxDuration = 15;
    
    // Путь к FFMpeg (будет найден автоматически или из конфига)
    protected ?string $ffmpegPath = null;
    protected ?string $ffprobePath = null;
    
    // Поддерживаемые форматы видео
    protected array $supportedFormats = [
        'video/mp4',
        'video/quicktime',      // MOV
        'video/x-m4v',          // M4V
        'video/x-msvideo',      // AVI
        'video/webm',           // WebM
        'video/x-matroska',     // MKV
        'video/hevc',           // HEVC
        'video/3gpp',           // 3GP
        'video/3gpp2',          // 3G2
        'application/octet-stream', // Для iPhone HEVC видео
    ];
    
    // Поддерживаемые расширения
    protected array $supportedExtensions = [
        'mp4', 'mov', 'avi', 'm4v', 'webm', 'mkv', 
        'hevc', '3gp', '3g2', 'mts', 'ts'
    ];

    public function __construct(S3Service $s3Service)
    {
        $this->s3Service = $s3Service;
        $this->findFFMpeg();
    }

    /**
     * Найти FFMpeg в системе
     */
    protected function findFFMpeg(): void
    {
        // Пробуем из конфига
        $configFfmpeg = config('laravel-ffmpeg.ffmpeg.binaries');
        $configFfprobe = config('laravel-ffmpeg.ffprobe.binaries');
        
        // Для Windows проверяем стандартные пути
        if (strtoupper(substr(PHP_OS, 0, 3)) === 'WIN') {
            $possiblePaths = [
                env('FFMPEG_BINARIES'),
                $configFfmpeg,
                'C:\\ffmpeg\\bin\\ffmpeg.exe',
                'C:\\Program Files\\ffmpeg\\bin\\ffmpeg.exe',
                'C:\\Program Files (x86)\\ffmpeg\\bin\\ffmpeg.exe',
                storage_path('app/ffmpeg/ffmpeg.exe'),
            ];
            
            foreach ($possiblePaths as $path) {
                if ($path && file_exists($path)) {
                    $this->ffmpegPath = $path;
                    $this->ffprobePath = str_replace('ffmpeg.exe', 'ffprobe.exe', $path);
                    Log::info('[VideoToGifService] Found FFMpeg at: ' . $this->ffmpegPath);
                    return;
                }
            }
            
            // Проверяем в PATH
            $whereResult = shell_exec('where ffmpeg 2>nul');
            if ($whereResult) {
                $this->ffmpegPath = trim($whereResult);
                $this->ffprobePath = str_replace('ffmpeg', 'ffprobe', $this->ffmpegPath);
                Log::info('[VideoToGifService] Found FFMpeg in PATH: ' . $this->ffmpegPath);
                return;
            }
        } else {
            // Для Linux/Mac
            $possiblePaths = [
                env('FFMPEG_BINARIES'),
                $configFfmpeg,
                '/usr/bin/ffmpeg',
                '/usr/local/bin/ffmpeg',
            ];
            
            foreach ($possiblePaths as $path) {
                if ($path && file_exists($path)) {
                    $this->ffmpegPath = $path;
                    $this->ffprobePath = str_replace('ffmpeg', 'ffprobe', $path);
                    Log::info('[VideoToGifService] Found FFMpeg at: ' . $this->ffmpegPath);
                    return;
                }
            }
            
            // Проверяем в PATH
            $whichResult = shell_exec('which ffmpeg 2>/dev/null');
            if ($whichResult) {
                $this->ffmpegPath = trim($whichResult);
                $this->ffprobePath = str_replace('ffmpeg', 'ffprobe', $this->ffmpegPath);
                Log::info('[VideoToGifService] Found FFMpeg in PATH: ' . $this->ffmpegPath);
                return;
            }
        }
        
        Log::warning('[VideoToGifService] FFMpeg not found in system');
    }

    /**
     * Проверить, установлен ли FFMpeg
     */
    public function isFFMpegInstalled(): bool
    {
        return $this->ffmpegPath !== null && file_exists($this->ffmpegPath);
    }

    /**
     * Получить путь к FFMpeg
     */
    public function getFFMpegPath(): ?string
    {
        return $this->ffmpegPath;
    }

    /**
     * Проверить, является ли файл поддерживаемым видео
     */
    public function isSupported(UploadedFile $file): bool
    {
        $mimeType = $file->getMimeType();
        $extension = strtolower($file->getClientOriginalExtension());
        
        return in_array($mimeType, $this->supportedFormats) || 
               in_array($extension, $this->supportedExtensions);
    }

    /**
     * Получить длительность видео в секундах
     */
    public function getVideoDuration(string $path): float
    {
        if (!$this->isFFMpegInstalled()) {
            Log::error('[VideoToGifService] Cannot get duration - FFMpeg not installed');
            return 0;
        }
        
        try {
            $cmd = sprintf(
                '"%s" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "%s" 2>&1',
                $this->ffprobePath,
                $path
            );
            
            Log::debug('[VideoToGifService] Getting duration with command: ' . $cmd);
            
            $output = shell_exec($cmd);
            $duration = (float) trim($output);
            
            Log::info('[VideoToGifService] Video duration: ' . $duration . ' seconds');
            return $duration;
            
        } catch (\Exception $e) {
            Log::error('[VideoToGifService] Error getting video duration: ' . $e->getMessage());
            return 0;
        }
    }

    /**
     * Проверить, не превышает ли длительность видео максимум
     */
    public function isDurationValid(string $path): bool
    {
        $duration = $this->getVideoDuration($path);
        return $duration > 0 && $duration <= $this->maxDuration;
    }

    /**
     * Конвертировать видео в GIF
     */
    public function convertToGif(UploadedFile $file): array
    {
        Log::info('[VideoToGifService] === Starting video conversion ===');
        Log::info('[VideoToGifService] File info', [
            'original_name' => $file->getClientOriginalName(),
            'mime_type' => $file->getMimeType(),
            'size' => $file->getSize(),
            'extension' => $file->getClientOriginalExtension(),
        ]);
        
        // Проверяем FFMpeg
        if (!$this->isFFMpegInstalled()) {
            Log::error('[VideoToGifService] FFMpeg not installed!');
            throw new \RuntimeException(
                'FFMpeg не установлен на сервере. ' .
                'Пожалуйста, установите FFMpeg или используйте изображения вместо видео.'
            );
        }
        
        $tempPath = $file->getPathname();
        
        // Проверяем длительность
        $duration = $this->getVideoDuration($tempPath);
        
        if ($duration <= 0) {
            Log::error('[VideoToGifService] Could not determine video duration');
            throw new \InvalidArgumentException('Не удалось определить длительность видео. Возможно, файл повреждён.');
        }
        
        if ($duration > $this->maxDuration) {
            Log::warning('[VideoToGifService] Video too long', [
                'duration' => $duration,
                'max' => $this->maxDuration
            ]);
            throw new \InvalidArgumentException(
                "Видео слишком длинное ({$duration} сек). Максимум: {$this->maxDuration} секунд"
            );
        }
        
        // Получаем информацию о видео
        $videoInfo = $this->getVideoInfo($tempPath);
        $width = $videoInfo['width'] ?? 480;
        $height = $videoInfo['height'] ?? 480;
        
        Log::info('[VideoToGifService] Video dimensions', ['width' => $width, 'height' => $height]);
        
        // Рассчитываем новый размер (максимум 480px по большей стороне для GIF)
        $maxSize = 480;
        if ($width > $height) {
            $newWidth = min($width, $maxSize);
            $newHeight = (int) round($newWidth * $height / $width);
        } else {
            $newHeight = min($height, $maxSize);
            $newWidth = (int) round($newHeight * $width / $height);
        }
        
        // Убедимся что размеры чётные (требование ffmpeg)
        $newWidth = $newWidth % 2 === 0 ? $newWidth : $newWidth + 1;
        $newHeight = $newHeight % 2 === 0 ? $newHeight : $newHeight + 1;
        
        Log::info('[VideoToGifService] Target GIF dimensions', ['width' => $newWidth, 'height' => $newHeight]);
        
        // Создаём временные файлы
        $palettePath = sys_get_temp_dir() . '/' . Str::uuid() . '_palette.png';
        $gifPath = sys_get_temp_dir() . '/' . Str::uuid() . '.gif';
        
        try {
            // Шаг 1: Генерируем палитру для лучшего качества
            Log::info('[VideoToGifService] Step 1: Generating palette...');
            
            $paletteCmd = sprintf(
                '"%s" -y -i "%s" -vf "fps=10,scale=%d:%d:flags=lanczos,palettegen=stats_mode=diff" "%s" 2>&1',
                $this->ffmpegPath,
                $tempPath,
                $newWidth,
                $newHeight,
                $palettePath
            );
            
            Log::debug('[VideoToGifService] Palette command: ' . $paletteCmd);
            
            $startTime = microtime(true);
            $paletteOutput = shell_exec($paletteCmd);
            $paletteTime = round(microtime(true) - $startTime, 2);
            
            Log::info('[VideoToGifService] Palette generation took ' . $paletteTime . 's');
            
            if (!file_exists($palettePath)) {
                Log::error('[VideoToGifService] Palette generation failed', [
                    'output' => $paletteOutput
                ]);
                throw new \RuntimeException('Не удалось создать палитру для GIF: ' . $paletteOutput);
            }
            
            // Шаг 2: Конвертируем в GIF используя палитру
            Log::info('[VideoToGifService] Step 2: Converting to GIF...');
            
            $gifCmd = sprintf(
                '"%s" -y -i "%s" -i "%s" -lavfi "fps=10,scale=%d:%d:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" "%s" 2>&1',
                $this->ffmpegPath,
                $tempPath,
                $palettePath,
                $newWidth,
                $newHeight,
                $gifPath
            );
            
            Log::debug('[VideoToGifService] GIF command: ' . $gifCmd);
            
            $startTime = microtime(true);
            $gifOutput = shell_exec($gifCmd);
            $gifTime = round(microtime(true) - $startTime, 2);
            
            Log::info('[VideoToGifService] GIF conversion took ' . $gifTime . 's');
            
            // Удаляем палитру
            if (file_exists($palettePath)) {
                unlink($palettePath);
            }
            
            if (!file_exists($gifPath)) {
                Log::error('[VideoToGifService] GIF conversion failed', [
                    'output' => $gifOutput
                ]);
                throw new \RuntimeException('Не удалось конвертировать видео в GIF: ' . $gifOutput);
            }
            
            $gifSize = filesize($gifPath);
            Log::info('[VideoToGifService] GIF created successfully', [
                'path' => $gifPath,
                'size' => $gifSize,
                'size_mb' => round($gifSize / 1024 / 1024, 2)
            ]);
            
            // Шаг 3: Загружаем на S3
            Log::info('[VideoToGifService] Step 3: Uploading to S3...');
            
            $gifContent = file_get_contents($gifPath);
            $s3Filename = 'gifs/' . Str::uuid() . '.gif';
            
            $this->s3Service->uploadToS3WithAcl($s3Filename, $gifContent, 'image/gif');
            $publicUrl = $this->s3Service->getPublicUrl($s3Filename);
            
            // Удаляем временный GIF
            unlink($gifPath);
            
            Log::info('[VideoToGifService] === Conversion complete! ===', [
                'url' => $publicUrl,
                'total_time' => $paletteTime + $gifTime . 's'
            ]);
            
            return [
                'success' => true,
                'url' => $publicUrl,
                'duration' => $duration,
                'original_size' => "{$width}x{$height}",
                'gif_size' => "{$newWidth}x{$newHeight}",
                'file_size' => $gifSize,
            ];
            
        } catch (\Exception $e) {
            // Очистка временных файлов
            if (isset($gifPath) && file_exists($gifPath)) {
                unlink($gifPath);
            }
            if (isset($palettePath) && file_exists($palettePath)) {
                unlink($palettePath);
            }
            
            Log::error('[VideoToGifService] === Conversion FAILED ===', [
                'error' => $e->getMessage(),
            ]);
            
            throw $e;
        }
    }

    /**
     * Получить информацию о видео (размеры)
     */
    protected function getVideoInfo(string $path): array
    {
        if (!$this->isFFMpegInstalled()) {
            return ['width' => 480, 'height' => 480];
        }
        
        try {
            $cmd = sprintf(
                '"%s" -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "%s" 2>&1',
                $this->ffprobePath,
                $path
            );
            
            $output = trim(shell_exec($cmd));
            $parts = explode(',', $output);
            
            if (count($parts) >= 2) {
                return [
                    'width' => (int) $parts[0],
                    'height' => (int) $parts[1],
                ];
            }
        } catch (\Exception $e) {
            Log::warning('[VideoToGifService] Could not get video info: ' . $e->getMessage());
        }
        
        return ['width' => 480, 'height' => 480];
    }

    /**
     * Конвертировать видео из base64 в GIF
     */
    public function convertBase64ToGif(string $base64): array
    {
        Log::info('[VideoToGifService] Converting base64 video...');
        
        // Проверяем формат base64
        if (!preg_match('/^data:video\/(\w+);base64,/', $base64, $matches)) {
            throw new \InvalidArgumentException('Неверный формат base64 видео');
        }
        
        $extension = $matches[1];
        $base64Data = substr($base64, strpos($base64, ',') + 1);
        $decoded = base64_decode($base64Data);
        
        if ($decoded === false) {
            throw new \RuntimeException('Не удалось декодировать base64');
        }
        
        // Сохраняем во временный файл
        $tempPath = sys_get_temp_dir() . '/' . Str::uuid() . '.' . $extension;
        file_put_contents($tempPath, $decoded);
        
        Log::info('[VideoToGifService] Saved base64 to temp file', [
            'path' => $tempPath,
            'size' => strlen($decoded)
        ]);
        
        try {
            // Создаём UploadedFile
            $file = new UploadedFile(
                $tempPath,
                'video.' . $extension,
                'video/' . $extension,
                null,
                true
            );
            
            return $this->convertToGif($file);
            
        } finally {
            // Удаляем временный файл
            if (file_exists($tempPath)) {
                unlink($tempPath);
            }
        }
    }

    /**
     * Получить максимальную длительность видео
     */
    public function getMaxDuration(): int
    {
        return $this->maxDuration;
    }

    /**
     * Получить список поддерживаемых форматов
     */
    public function getSupportedFormats(): array
    {
        return $this->supportedExtensions;
    }
}
