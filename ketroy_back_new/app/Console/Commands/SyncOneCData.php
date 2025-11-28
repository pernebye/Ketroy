<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use App\Services\OneCSyncService;

class SyncOneCData extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'sync:one-c';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Synchronize data with 1C';

    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     */
    public function handle(OneCSyncService $service)
    {
        foreach (User::all() as $user) {
            $data = $service->getBonusesAndDiscounts($user->id);
            if ($data) {
                $user->update([
                    'bonus_balance' => $data['bonuses'],
                    'discount' => $data['discount'],
                ]);
            }
        }

        $this->info('Synchronization completed.');
    }
}
