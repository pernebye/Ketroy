<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class ClothingAnalyzerController extends Controller
{
    /**
     * Анализ ярлыка одежды через OpenAI Vision API
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function analyzeLabel(Request $request): JsonResponse
    {
        // Валидация для мобильных форматов камер
        $validator = Validator::make($request->all(), [
            'image' => 'required|file|mimes:jpeg,png,jpg,heic,heif|max:10240', // 10MB
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'error' => 'Некорректное изображение. Поддерживаемые форматы: JPEG, PNG, HEIC, HEIF. Максимальный размер: 10MB',
                'details' => $validator->errors()
            ], 400);
        }

        try {
            // Проверяем наличие API ключа
            $apiKey = env('OPENAI_API_KEY');
            if (!$apiKey) {
                return response()->json([
                    'success' => false,
                    'error' => 'API ключ OpenAI не настроен. Добавьте OPENAI_API_KEY в .env файл'
                ], 500);
            }

            // Получаем и обрабатываем изображение
            $image = $request->file('image');
            $imageBase64 = $this->processImage($image);
            
            if (!$imageBase64) {
                return response()->json([
                    'success' => false,
                    'error' => 'Ошибка обработки изображения'
                ], 400);
            }

            // Отправляем запрос к OpenAI
            $startTime = microtime(true);
            $response = $this->callOpenAI($imageBase64, $apiKey);
            $processingTime = round((microtime(true) - $startTime), 2);

            if (!$response['success']) {
                return response()->json([
                    'success' => false,
                    'error' => $response['error']
                ], 500);
            }

            // Простое логирование
            Log::info('Анализ ярлыка выполнен', [
                'processing_time' => $processingTime,
                'image_size_kb' => round($image->getSize() / 1024, 1)
            ]);

            return response()->json([
                'success' => true,
                'analysis' => $response['analysis'],
                'processing_time' => $processingTime,
                'timestamp' => now()->toISOString()
            ]);

        } catch (\Exception $e) {
            Log::error('Ошибка анализа ярлыка: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'error' => 'Внутренняя ошибка сервера при анализе изображения'
            ], 500);
        }
    }

    /**
     * Обрабатывает изображение для отправки в OpenAI
     * Поддерживает только реальные форматы мобильных камер: JPEG, PNG, HEIC/HEIF
     * 
     * @param \Illuminate\Http\UploadedFile $image
     * @return string|null
     */
    private function processImage($image): ?string
    {
        try {
            // Получаем информацию о файле
            $extension = strtolower($image->getClientOriginalExtension());
            $mimeType = $image->getMimeType();
            
            // Обрабатываем HEIC/HEIF файлы от iPhone
            if (in_array($extension, ['heic', 'heif']) || 
                in_array($mimeType, ['image/heic', 'image/heif'])) {
                return $this->convertHeicToJpeg($image);
            }
            
            // Читаем содержимое файла
            $imageContent = file_get_contents($image->getPathname());
            
            // Оптимизируем размер изображения если нужно
            $imageInfo = getimagesize($image->getPathname());
            if ($imageInfo && ($imageInfo[0] > 1024 || $imageInfo[1] > 1024)) {
                // Создаем изображение из файла
                switch ($imageInfo[2]) {
                    case IMAGETYPE_JPEG:
                        $sourceImage = imagecreatefromjpeg($image->getPathname());
                        break;
                    case IMAGETYPE_PNG:
                        $sourceImage = imagecreatefrompng($image->getPathname());
                        break;
                    default:
                        return base64_encode($imageContent);
                }

                if ($sourceImage) {
                    // Вычисляем новые размеры
                    $maxSize = 1024;
                    $width = $imageInfo[0];
                    $height = $imageInfo[1];
                    
                    if ($width > $height) {
                        $newWidth = $maxSize;
                        $newHeight = intval($height * ($maxSize / $width));
                    } else {
                        $newHeight = $maxSize;
                        $newWidth = intval($width * ($maxSize / $height));
                    }

                    // Создаем уменьшенное изображение
                    $resizedImage = imagecreatetruecolor($newWidth, $newHeight);
                    imagecopyresampled($resizedImage, $sourceImage, 0, 0, 0, 0, $newWidth, $newHeight, $width, $height);

                    // Сохраняем в буфер
                    ob_start();
                    imagejpeg($resizedImage, null, 85);
                    $imageContent = ob_get_contents();
                    ob_end_clean();

                    imagedestroy($sourceImage);
                    imagedestroy($resizedImage);
                }
            }

            return base64_encode($imageContent);
            
        } catch (\Exception $e) {
            Log::error('Ошибка обработки изображения: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Конвертирует HEIC/HEIF файлы от iPhone в JPEG
     * 
     * @param \Illuminate\Http\UploadedFile $image
     * @return string|null
     */
    private function convertHeicToJpeg($image): ?string
    {
        try {
            // Способ 1: Попробуем использовать Imagick (если установлен)
            if (extension_loaded('imagick')) {
                $imagick = new \Imagick($image->getPathname());
                $imagick->setImageFormat('jpeg');
                $imagick->setImageCompressionQuality(85);
                
                // Оптимизируем размер
                $width = $imagick->getImageWidth();
                $height = $imagick->getImageHeight();
                
                if ($width > 1024 || $height > 1024) {
                    if ($width > $height) {
                        $newWidth = 1024;
                        $newHeight = intval($height * (1024 / $width));
                    } else {
                        $newHeight = 1024;
                        $newWidth = intval($width * (1024 / $height));
                    }
                    $imagick->resizeImage($newWidth, $newHeight, \Imagick::FILTER_LANCZOS, 1);
                }
                
                $jpegData = $imagick->getImageBlob();
                $imagick->clear();
                
                return base64_encode($jpegData);
            }
            
            // Способ 2: Попробуем через внешнюю команду (если доступна)
            if ($this->isCommandAvailable('heif-convert')) {
                $tempJpeg = tempnam(sys_get_temp_dir(), 'heic_') . '.jpg';
                $command = "heif-convert " . escapeshellarg($image->getPathname()) . " " . escapeshellarg($tempJpeg);
                
                exec($command, $output, $returnCode);
                
                if ($returnCode === 0 && file_exists($tempJpeg)) {
                    $jpegContent = file_get_contents($tempJpeg);
                    unlink($tempJpeg);
                    
                    // Оптимизируем размер получившегося JPEG
                    $tempPath = tempnam(sys_get_temp_dir(), 'opt_') . '.jpg';
                    file_put_contents($tempPath, $jpegContent);
                    
                    $imageInfo = getimagesize($tempPath);
                    if ($imageInfo && ($imageInfo[0] > 1024 || $imageInfo[1] > 1024)) {
                        $sourceImage = imagecreatefromjpeg($tempPath);
                        if ($sourceImage) {
                            $width = $imageInfo[0];
                            $height = $imageInfo[1];
                            
                            if ($width > $height) {
                                $newWidth = 1024;
                                $newHeight = intval($height * (1024 / $width));
                            } else {
                                $newHeight = 1024;
                                $newWidth = intval($width * (1024 / $height));
                            }
                            
                            $resizedImage = imagecreatetruecolor($newWidth, $newHeight);
                            imagecopyresampled($resizedImage, $sourceImage, 0, 0, 0, 0, $newWidth, $newHeight, $width, $height);
                            
                            ob_start();
                            imagejpeg($resizedImage, null, 85);
                            $jpegContent = ob_get_contents();
                            ob_end_clean();
                            
                            imagedestroy($sourceImage);
                            imagedestroy($resizedImage);
                        }
                    }
                    
                    unlink($tempPath);
                    return base64_encode($jpegContent);
                }
            }
            
            // Способ 3: Отправляем HEIC как есть (OpenAI может поддерживать)
            Log::info('HEIC конвертация недоступна, отправляем как есть');
            $heicContent = file_get_contents($image->getPathname());
            return base64_encode($heicContent);
            
        } catch (\Exception $e) {
            Log::error('Ошибка конвертации HEIC: ' . $e->getMessage());
            
            // В крайнем случае отправляем как есть
            $heicContent = file_get_contents($image->getPathname());
            return base64_encode($heicContent);
        }
    }

    /**
     * Проверяет доступность внешней команды
     * 
     * @param string $command
     * @return bool
     */
    private function isCommandAvailable(string $command): bool
    {
        $check = shell_exec("which $command 2>/dev/null");
        return !empty($check);
    }

    /**
     * Отправляет запрос к OpenAI Vision API
     * 
     * @param string $imageBase64
     * @param string $apiKey
     * @return array
     */
    private function callOpenAI(string $imageBase64, string $apiKey): array
    {
        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $apiKey,
                'Content-Type' => 'application/json'
            ])->timeout(60)->post('https://api.openai.com/v1/chat/completions', [
                'model' => 'gpt-4o',
                'messages' => [
                    [
                        'role' => 'user',
                        'content' => [
                            [
                                'type' => 'text',
                                'text' => 'Проанализируй это изображение этикетки одежды и предоставь следующую информацию:

1. ТИП ИЗДЕЛИЯ: Определи, что это за предмет одежды (рубашка, брюки, свитер и т.д.)

2. СОСТАВ МАТЕРИАЛА: Укажи состав ткани, если видно на этикетке

3. РЕКОМЕНДАЦИИ ПО УХОДУ: Подробно расшифруй все символы на этикетке по уходу:
   - Стирка (температура, режим)
   - Отбеливание (разрешено/запрещено)
   - Сушка (способ сушки)
   - Глажка (температура, особенности)
   - Химчистка (тип, если необходима)

4. ДОПОЛНИТЕЛЬНЫЕ СОВЕТЫ: Практические советы по уходу за изделием

Отвечай на русском языке простым и понятным текстом, без использования JSON или других форматов структурированных данных. Если какая-то информация не видна на этикетке, так и укажи.'
                            ],
                            [
                                'type' => 'image_url',
                                'image_url' => [
                                    'url' => 'data:image/jpeg;base64,' . $imageBase64
                                ]
                            ]
                        ]
                    ]
                ],
                'max_tokens' => 1000
            ]);

            if (!$response->successful()) {
                $error = $response->json();
                return [
                    'success' => false,
                    'error' => 'Ошибка OpenAI API: ' . ($error['error']['message'] ?? 'Неизвестная ошибка')
                ];
            }

            $data = $response->json();
            
            return [
                'success' => true,
                'analysis' => $data['choices'][0]['message']['content']
            ];

        } catch (\Exception $e) {
            return [
                'success' => false,
                'error' => 'Ошибка подключения к OpenAI: ' . $e->getMessage()
            ];
        }
    }



    /**
     * Проверка работоспособности сервиса
     * 
     * @return JsonResponse
     */
    public function health(): JsonResponse
    {
        $apiKey = env('OPENAI_API_KEY');
        
        // Проверяем доступные возможности для мобильных форматов
        $capabilities = [
            'imagick_available' => extension_loaded('imagick'),
            'gd_available' => extension_loaded('gd'),
            'heif_convert_available' => $this->isCommandAvailable('heif-convert')
        ];
        
        return response()->json([
            'service' => 'Clothing Label Analyzer',
            'status' => 'online',
            'openai_configured' => !empty($apiKey),
            'timestamp' => now()->toISOString(),
            'supported_formats' => ['jpeg', 'jpg', 'png', 'heic', 'heif'],
            'max_file_size' => '10MB',
            'capabilities' => $capabilities,
            'heic_conversion' => $capabilities['imagick_available'] || $capabilities['heif_convert_available'] ? 'available' : 'basic'
        ]);
    }
} 