<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\AnalyticsService;

class AnalyzePromotions extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'analytics:analyze-promotions';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Анализ эффективности акций';
    protected $analyticsService;

    public function __construct(AnalyticsService $analyticsService)
    {
        parent::__construct();
        $this->analyticsService = $analyticsService;
    }

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $results = $this->analyticsService->getPromoCodeUsage(now()->subMonth(), now());
        $this->info("Анализ завершен: " . $results->count() . " записей.");
    }
}
