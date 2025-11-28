<?php

namespace App\Jobs;

use App\Models\NewsBlock;
use App\Services\S3Service;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class UploadBlockMedia implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $blockId;
    protected $fileBase64;

    public function __construct(int $blockId, string $fileBase64)
    {
        $this->blockId = $blockId;
        $this->fileBase64 = $fileBase64;
    }

    public function handle(S3Service $s3Service)
    {
        $mediaPath = $s3Service->uploadBase64($this->fileBase64);

        NewsBlock::where('id', $this->blockId)->update([
            'media_path' => $mediaPath
        ]);
    }
}
