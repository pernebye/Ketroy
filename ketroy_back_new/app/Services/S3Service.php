<?php

namespace App\Services;

use Illuminate\Support\Facades\Storage;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Aws\S3\S3Client;


class S3Service
{
    protected ?S3Client $s3Client = null;
    
    /**
     * Получить S3 клиент
     */
    protected function getS3Client(): S3Client
    {
        if ($this->s3Client === null) {
            $this->s3Client = new S3Client([
                'version' => 'latest',
                'region' => config('filesystems.disks.s3.region'),
                'endpoint' => config('filesystems.disks.s3.endpoint'),
                'credentials' => [
                    'key' => config('filesystems.disks.s3.key'),
                    'secret' => config('filesystems.disks.s3.secret'),
                ],
                'use_path_style_endpoint' => true, // Для S3-совместимых хранилищ
                'http' => [
                    'verify' => false, // Отключаем проверку SSL для PS Cloud
                ],
            ]);
        }
        return $this->s3Client;
    }

    public function getFilePath(Request $request, ?string $field = 'file'): string
    {
        if ($request->hasFile($field)) {
            $folder = 'images';
            if ($request->type == 'video') {
                $folder = 'videos';
            }
            
            $file = $request->file($field);
            $filename = $folder . '/' . Str::uuid() . '.' . $file->getClientOriginalExtension();
            
            // Загружаем напрямую через S3 клиент с ACL
            $this->uploadToS3WithAcl($filename, file_get_contents($file->getRealPath()), $file->getMimeType());

            return $this->getPublicUrl($filename);
        } else {
            return $request->file_path;
        }
    }

    public function uploadBase64(string $base64): string
    {
        // Проверка формата base64 с поддержкой image/* и video/*
        if (preg_match('/^data:(image|video)\/(\w+);base64,/', $base64, $matches)) {
            $type = $matches[1];      // image или video
            $extension = $matches[2]; // jpg, png, mp4 и т.п.
            $base64 = substr($base64, strpos($base64, ',') + 1);
        } else {
            throw new \InvalidArgumentException('Неверный формат base64');
        }

        // Декодируем base64
        $decoded = base64_decode($base64);
        if ($decoded === false) {
            throw new \RuntimeException('Не удалось декодировать base64 строку');
        }

        // Определяем папку и MIME тип
        $folder = $type === 'image' ? 'images' : 'videos';
        $mimeType = $type . '/' . $extension;
        
        // Генерируем путь
        $filename = $folder . '/' . Str::uuid() . '.' . $extension;

        // Загружаем напрямую через S3 клиент с публичным ACL
        $this->uploadToS3WithAcl($filename, $decoded, $mimeType);

        return $this->getPublicUrl($filename);
    }
    
    /**
     * Загрузить файл в S3 с публичным ACL
     */
    public function uploadToS3WithAcl(string $key, string $body, string $contentType): void
    {
        $bucket = config('filesystems.disks.s3.bucket');
        
        \Log::info('[S3Service] Uploading to S3', [
            'bucket' => $bucket,
            'key' => $key,
            'contentType' => $contentType,
        ]);
        
        try {
            $this->getS3Client()->putObject([
                'Bucket' => $bucket,
                'Key' => $key,
                'Body' => $body,
                'ContentType' => $contentType,
                'ACL' => 'public-read', // Явно указываем публичный доступ
            ]);
            \Log::info('[S3Service] Upload successful');
        } catch (\Exception $e) {
            \Log::error('[S3Service] Upload failed: ' . $e->getMessage());
            throw $e;
        }
    }
    
    /**
     * Получить публичный URL файла
     */
    public function getPublicUrl(string $key): string
    {
        $baseUrl = config('filesystems.disks.s3.url');
        return rtrim($baseUrl, '/') . '/' . ltrim($key, '/');
    }
}
