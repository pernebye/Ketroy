<?php

namespace App\Console\Commands;

use App\Models\Purchase;
use App\Models\User;
use App\Services\OneCApiService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class SyncClientsPurchases extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:sync-clients-purchases';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Обработка и сохранение покупок клиентов';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $users = User::all();
        $oneCService = new OneCApiService();
        foreach ($users as $user) {
            $purchasesData = $oneCService->getClientPurchases(str_replace('+7', '8', $user->country_code) . $user->phone);
            $purchases = $purchasesData['purchases'] ?? [];
            foreach ($purchases as $purchase) {
                $purchaseDate = Carbon::parse($purchase['purchaseDate'])->format('Y-m-d');
                $exists = Purchase::where('user_id', $user->id)
                    ->whereDate('purchased_at', $purchaseDate)
                    ->exists();
                if (!$exists) {
                    Purchase::create([
                        'user_id' => $user->id,
                        'purchased_at' => $purchaseDate,
                        'total_price' => $purchase['purchaseAmount'],
                    ]);
                }
            }
        }
        
        $this->info('Покупки обработаны и сохранены.');
    }

}
