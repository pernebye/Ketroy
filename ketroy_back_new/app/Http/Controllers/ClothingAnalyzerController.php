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
        // Проверка авторизации
        if (!$request->user()) {
            Log::warning('Clothing Analyzer: Unauthorized request');
            return response()->json([
                'success' => false,
                'error' => 'Требуется авторизация'
            ], 401);
        }

        // Логирование входящего запроса
        Log::info('Clothing Analyzer: Incoming request', [
            'user_id' => $request->user()->id,
            'has_file' => $request->hasFile('image'),
            'file_size' => $request->file('image')?->getSize(),
            'mime_type' => $request->file('image')?->getMimeType(),
            'language' => $request->input('language'),
            'request_keys' => $request->keys()
        ]);

        // Валидация для мобильных форматов камер
        $validator = Validator::make($request->all(), [
            'image' => 'required|file|mimes:jpeg,png,jpg,heic,heif|max:10240', // 10MB
            'language' => 'nullable|string|in:en,ru,kk,tr', // Поддерживаемые языки
        ]);

        if ($validator->fails()) {
            Log::warning('Clothing Analyzer: Validation failed', [
                'errors' => $validator->errors()->toArray()
            ]);
            
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
            Log::info('Clothing Analyzer: Processing image', [
                'original_name' => $image->getClientOriginalName(),
                'size' => $image->getSize()
            ]);
            
            $imageBase64 = $this->processImage($image);
            
            if (!$imageBase64) {
                Log::error('Clothing Analyzer: Failed to process image');
                return response()->json([
                    'success' => false,
                    'error' => 'Ошибка обработки изображения'
                ], 400);
            }

            Log::info('Clothing Analyzer: Image processed successfully', [
                'base64_size' => strlen($imageBase64)
            ]);

            // Получаем язык из запроса (по умолчанию русский)
            $language = $request->input('language', 'ru');

            // Отправляем запрос к OpenAI
            $startTime = microtime(true);
            $response = $this->callOpenAI($imageBase64, $apiKey, $language);
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
            Log::error('Ошибка анализа ярлыка', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return response()->json([
                'success' => false,
                'error' => 'Внутренняя ошибка сервера при анализе изображения',
                'debug' => env('APP_DEBUG') ? $e->getMessage() : null
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
     * @param string $language Язык ответа (en, ru, kk, tr)
     * @return array
     */
    private function callOpenAI(string $imageBase64, string $apiKey, string $language = 'ru'): array
    {
        try {
            Log::info('Clothing Analyzer: callOpenAI started', [
                'language' => $language,
                'model' => env('OPENAI_MODEL', 'gpt-5-nano'),
                'api_key_exists' => !empty($apiKey),
                'image_size' => strlen($imageBase64)
            ]);

            $model = env('OPENAI_MODEL', 'gpt-5-nano');
            
            // Определяем инструкцию по языку
            $languageInstruction = $this->getLanguageInstruction($language);
            
            // Динамический промпт в зависимости от языка
            $prompts = [
                'ru' => 'Это изображение этикетки одежды? 

ЕСЛИ ДА - проанализируй кратко и вежливо на РУССКОМ:
📌 Тип изделия: [описание]
📌 Материал: [состав]
📌 Рекомендации по уходу: [стирка, сушка, глажка]
📌 Советы: [практические рекомендации]

ЕСЛИ НЕТ - ответь кратко и вежливо на РУССКОМ (без длинных текстов):
"Привет! 👋 Я не вижу этикетку на фото. Отправь, пожалуйста, четкое фото этикетки - я помогу!" 
Добавь легкий юмор/шутку если видишь человека вместо этикетки.',
                
                'en' => 'Is this a clothing label image?

IF YES - analyze briefly and politely in ENGLISH:
📌 Type of clothing: [description]
📌 Material: [composition]
📌 Care recommendations: [washing, drying, ironing]
📌 Tips: [practical advice]

IF NO - answer briefly in ENGLISH (short message):
"Hi! 👋 I don\'t see a clothing label here. Please send a clear photo of the label - I\'ll help!"
Add a light joke if you see a person instead of a label.',
                
                'kk' => 'Бұл киімнің этикеткасының суреті ме?

ЕГЕР ҚЫ - қысқаша және құрметті түрде ҚАЗАҚША сипатта:
📌 Киім түрі: [сипаттамасы]
📌 Материалы: [құрамасы]
📌 Қараусы бойынша ұсынымдар: [жуу, кептіру, үтіктеу]
📌 Кеңестер: [іс-әрекетті ұсынымдар]

ЕГЕР ЖОҚ - қысқаша және құрметті түрде ҚАЗАҚША (ұзын мәтін жоқ):
"Сәлем! 👋 Мен этикетканы көрмедім. Өтінішінме, этикетканың нақты суретін жіберіңіз - мен көмектесемін!"
Егер адамды көрсеңіз, жеңіл күлкі қосыңыз.',
                
                'tr' => 'Bu bir giysi etiketi görüntüsü mü?

EVET İSE - kısaca ve nazikçe TÜRKÇE analiz et:
📌 Giysi türü: [açıklama]
📌 Malzeme: [bileşim]
📌 Bakım önerileri: [yıkama, kurutma, ütüleme]
📌 İpuçları: [pratik tavsiyeler]

HAYIR İSE - kısaca ve nazikçe TÜRKÇE cevap ver (uzun mesaj yok):
"Merhaba! 👋 Etiketi göremiyorum. Lütfen etiketi net olarak fotoğrafla - yardım ederim!"
Eğer insan görürseniz hafif bir şaka ekleyin.',
            ];

            $fullPrompt = $languageInstruction . ($prompts[$language] ?? $prompts['ru']);

            Log::info('Clothing Analyzer: Full prompt that will be sent', [
                'language' => $language,
                'prompt' => $fullPrompt,
                'image_base64_first_100_chars' => substr($imageBase64, 0, 100),
                'image_base64_length' => strlen($imageBase64)
            ]);

            Log::debug('Clothing Analyzer: Sending request to OpenAI', [
                'model' => $model,
                'language_instruction' => $languageInstruction
            ]);
            
            $requestPayload = [
                'model' => $model,
                'messages' => [
                    [
                        'role' => 'user',
                        'content' => [
                            [
                                'type' => 'text',
                                'text' => $fullPrompt
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
                // Не ограничиваем токены - дав модели свободу для анализа изображения
                // max_tokens и max_completion_tokens удалены намеренно
            ];

            Log::info('Clothing Analyzer: Request payload structure', [
                'has_model' => isset($requestPayload['model']),
                'has_messages' => isset($requestPayload['messages']),
                'message_count' => count($requestPayload['messages']),
                'first_message_role' => $requestPayload['messages'][0]['role'],
                'content_items' => count($requestPayload['messages'][0]['content']),
                'has_token_limit' => isset($requestPayload['max_completion_tokens']) || isset($requestPayload['max_tokens']),
                'note' => 'No token limits set - model will generate as needed'
            ]);
            
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $apiKey,
                'Content-Type' => 'application/json'
            ])->withoutVerifying()
              ->timeout(60)->post('https://api.openai.com/v1/chat/completions', $requestPayload);

            if (!$response->successful()) {
                $error = $response->json();
                Log::error('Clothing Analyzer: OpenAI API error', [
                    'status' => $response->status(),
                    'error' => $error,
                    'language' => $language,
                    'model' => $model
                ]);
                
                return [
                    'success' => false,
                    'error' => 'Ошибка OpenAI API: ' . ($error['error']['message'] ?? 'Неизвестная ошибка')
                ];
            }

            $data = $response->json();
            
            Log::info('Clothing Analyzer: Full response from OpenAI', [
                'status_code' => $response->status(),
                'response_data' => json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
            ]);
            
            // Проверяем структуру ответа
            if (!isset($data['choices']) || !isset($data['choices'][0])) {
                Log::error('Clothing Analyzer: Invalid response structure', [
                    'response_keys' => array_keys($data),
                    'has_choices' => isset($data['choices'])
                ]);
                return [
                    'success' => false,
                    'error' => 'Неправильная структура ответа от OpenAI'
                ];
            }

            $analysisContent = $data['choices'][0]['message']['content'] ?? '';
            
            Log::info('Clothing Analyzer: Analysis content extracted', [
                'language' => $language,
                'content_length' => strlen($analysisContent),
                'content_preview' => substr($analysisContent, 0, 200),
                'full_content' => $analysisContent
            ]);
            
            return [
                'success' => true,
                'analysis' => $analysisContent
            ];

        } catch (\Exception $e) {
            Log::error('Clothing Analyzer: Exception in callOpenAI', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'language' => $language
            ]);
            
            return [
                'success' => false,
                'error' => 'Ошибка подключения к OpenAI: ' . $e->getMessage()
            ];
        }
    }



    /**
     * Получает инструкцию для ИИ на основе выбранного языка
     * Используется только для ПЕРВОГО анализа этикетки как предпочтительный язык ответа.
     * 
     * @param string $language Код языка (en, ru, kk, tr)
     * @return string
     */
    private function getLanguageInstruction(string $language): string
    {
        // Мягкая инструкция - предпочтительный язык, но не строгое требование
        $instructions = [
            'en' => 'Preferred response language: English. ',
            'ru' => 'Предпочтительный язык ответа: русский. ',
            'kk' => 'Жауаптың қалаулы тілі: қазақша. ',
            'tr' => 'Tercih edilen yanıt dili: Türkçe. ',
        ];
        
        return $instructions[$language] ?? $instructions['ru'];
    }

    /**
     * Продолжить чат с контекстом
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function chat(Request $request): JsonResponse
    {
        Log::info('AI Chat: Incoming request', [
            'user_id' => $request->user()?->id,
            'has_image' => $request->hasFile('image'),
            'message' => $request->input('message'),
            'language' => $request->input('language'),
            'chat_history_raw_type' => gettype($request->input('chat_history')),
        ]);

        // Проверка авторизации
        if (!$request->user()) {
            return response()->json([
                'success' => false,
                'error' => 'Требуется авторизация'
            ], 401);
        }

        // Парсим chat_history если это JSON строка (при отправке FormData)
        $chatHistoryInput = $request->input('chat_history', []);
        if (is_string($chatHistoryInput)) {
            $chatHistoryInput = json_decode($chatHistoryInput, true) ?? [];
        }
        
        // Подменяем в request для валидации
        $request->merge(['chat_history' => $chatHistoryInput]);

        $validator = Validator::make($request->all(), [
            'message' => 'required_without:image|string|max:2000',
            'image' => 'nullable|file|mimes:jpeg,png,jpg,heic,heif|max:10240',
            'chat_history' => 'required|array',
            'chat_history.*.role' => 'required|string|in:user,assistant',
            'chat_history.*.content' => 'required|string',
            'language' => 'nullable|string|in:en,ru,kk,tr',
        ]);

        if ($validator->fails()) {
            Log::warning('AI Chat: Validation failed', [
                'errors' => $validator->errors()->toArray(),
                'has_image' => $request->hasFile('image'),
                'message' => $request->input('message'),
                'chat_history_type' => gettype($chatHistoryInput),
                'chat_history_count' => is_array($chatHistoryInput) ? count($chatHistoryInput) : 0
            ]);
            
            return response()->json([
                'success' => false,
                'error' => 'Некорректные данные',
                'details' => $validator->errors()
            ], 400);
        }

        try {
            $apiKey = env('OPENAI_API_KEY');
            if (!$apiKey) {
                return response()->json([
                    'success' => false,
                    'error' => 'API ключ OpenAI не настроен'
                ], 500);
            }

            $language = $request->input('language', 'ru');
            $chatHistory = $chatHistoryInput;
            $userMessage = $request->input('message', '');
            
            // Системное сообщение для контекста чата
            $systemPrompt = $this->getChatSystemPrompt($language);
            
            // Формируем массив сообщений
            $messages = [
                ['role' => 'system', 'content' => $systemPrompt]
            ];
            
            // Добавляем историю чата
            foreach ($chatHistory as $msg) {
                $messages[] = [
                    'role' => $msg['role'],
                    'content' => $msg['content']
                ];
            }
            
            // Добавляем новое сообщение пользователя
            if ($request->hasFile('image')) {
                // Если есть изображение
                $image = $request->file('image');
                $imageBase64 = $this->processImage($image);
                
                if (!$imageBase64) {
                    return response()->json([
                        'success' => false,
                        'error' => 'Ошибка обработки изображения'
                    ], 400);
                }
                
                $content = [
                    ['type' => 'text', 'text' => $userMessage ?: 'Проанализируй эту этикетку'],
                    ['type' => 'image_url', 'image_url' => ['url' => 'data:image/jpeg;base64,' . $imageBase64]]
                ];
                $messages[] = ['role' => 'user', 'content' => $content];
            } else {
                // Только текст
                $messages[] = ['role' => 'user', 'content' => $userMessage];
            }

            $model = env('OPENAI_MODEL', 'gpt-5-nano');
            
            Log::info('AI Chat: Sending request', [
                'user_id' => $request->user()->id,
                'message_count' => count($messages),
                'has_image' => $request->hasFile('image'),
                'language' => $language
            ]);

            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $apiKey,
                'Content-Type' => 'application/json'
            ])->withoutVerifying()
              ->timeout(60)
              ->post('https://api.openai.com/v1/chat/completions', [
                  'model' => $model,
                  'messages' => $messages
              ]);

            if (!$response->successful()) {
                $error = $response->json();
                Log::error('AI Chat: OpenAI API error', [
                    'status' => $response->status(),
                    'error' => $error
                ]);
                
                return response()->json([
                    'success' => false,
                    'error' => 'Ошибка API: ' . ($error['error']['message'] ?? 'Неизвестная ошибка')
                ], 500);
            }

            $data = $response->json();
            $assistantMessage = $data['choices'][0]['message']['content'] ?? '';

            Log::info('AI Chat: Response received', [
                'user_id' => $request->user()->id,
                'response_length' => strlen($assistantMessage)
            ]);

            return response()->json([
                'success' => true,
                'message' => $assistantMessage,
                'timestamp' => now()->toISOString()
            ]);

        } catch (\Exception $e) {
            Log::error('AI Chat: Exception', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return response()->json([
                'success' => false,
                'error' => 'Внутренняя ошибка сервера'
            ], 500);
        }
    }

    /**
     * Получает системный промпт для чата
     * Язык передается только как предпочтение для ПЕРВОГО ответа.
     * Далее ИИ адаптируется к языку пользователя.
     */
    private function getChatSystemPrompt(string $initialLanguage): string
    {
        // Определяем начальный язык для первого ответа
        $languageHint = match($initialLanguage) {
            'kk' => 'қазақша (казахский)',
            'en' => 'English (английский)',
            'tr' => 'Türkçe (турецкий)',
            default => 'русский'
        };

        return "Ты - дружелюбный AI-помощник KETROY по уходу за одеждой.

⚠️ СТРОГИЕ ОГРАНИЧЕНИЯ:
Ты помогаешь ТОЛЬКО с темами, связанными с одеждой:
✅ Анализ этикеток одежды (символы стирки, сушки, глажки, химчистки)
✅ Советы по уходу за одеждой и тканями
✅ Рекомендации по стирке, сушке, глажке разных материалов
✅ Удаление пятен с одежды
✅ Хранение одежды
✅ Общие вопросы о тканях и материалах

❌ НЕ ОТВЕЧАЙ на вопросы, не связанные с одеждой:
- Математика, история, география, наука
- Программирование, технологии
- Политика, новости, события
- Рецепты, медицина, юридические вопросы
- Любые другие темы вне сферы одежды

Если пользователь спрашивает о чём-то вне твоей компетенции - вежливо откажи и напомни, что ты специализируешься только на уходе за одеждой. Можешь пошутить, но не отвечай по существу на посторонние вопросы.

ПРАВИЛА ОБЩЕНИЯ:
1. Отвечай КРАТКО, вежливо и с лёгким юмором.
2. АДАПТИРУЙСЯ к языку пользователя: если пользователь пишет на русском - отвечай на русском, на казахском - на казахском, на английском - на английском и т.д.
3. Если пользователь явно просит ответить на другом языке - отвечай на том языке, который он просит.
4. НЕ ТРЕБУЙ от пользователя писать на каком-либо конкретном языке.
5. Предпочтительный язык для ПЕРВОГО ответа (если контекст не ясен): {$languageHint}.

Если видишь этикетку на изображении - анализируй её.
Если этикетки нет - вежливо попроси отправить фото этикетки.";
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
            'heic_conversion' => $capabilities['imagick_available'] || $capabilities['heif_convert_available'] ? 'available' : 'basic',
            'supported_languages' => ['en', 'ru', 'kk', 'tr']
        ]);
    }
} 