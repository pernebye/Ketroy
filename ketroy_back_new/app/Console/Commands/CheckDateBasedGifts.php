<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\GiftService;

class CheckDateBasedGifts extends Command
{
    protected $signature = 'gifts:date-based';
    protected $description = 'Начисление подарков по акциям с типом по датам';

    public function handle()
    {
        $giftsService = new GiftService();
        $giftsService->checkAndAssignGiftByDatePromotions();
        $this->info('Подарки по датам успешно проверены.');
    }
}
