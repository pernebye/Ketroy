<?php

namespace App\Console\Commands;

use App\Models\Promotion;
use App\Models\User;
use App\Services\GiftService;
use Illuminate\Console\Command;

class CheckAccumulationGifts extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'gifts:accumulation';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Command description';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $activePromotions = Promotion::where('type', 'accumulation')
            ->where('is_archived', false)
            ->get();

        $users = User::all();

        $giftService = new GiftService();

        foreach ($activePromotions as $promotion) {
            foreach ($users as $user){
                $giftService->checkAndAssignGiftByPurchaseTotal($user, $promotion);
            }
        }
    }
}
