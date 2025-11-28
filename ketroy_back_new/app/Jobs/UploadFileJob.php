<?php
namespace App\Jobs;

use App\Models\Story;
use App\Services\S3Service;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class UploadFileJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected int $storyId;
    protected string $base64;
    protected string $column;

    public function __construct(int $storyId, string $base64, string $column)
    {
        $this->storyId = $storyId;
        $this->base64 = $base64;
        $this->column = $column;
    }

    public function handle(S3Service $s3Service): void
    {
        $filePath = $s3Service->uploadBase64($this->base64);

        Story::where('id', $this->storyId)
            ->update([$this->column => $filePath]);
    }
}
