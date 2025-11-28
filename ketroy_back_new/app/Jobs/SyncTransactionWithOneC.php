<?php

namespace App\Jobs;

use App\Services\OneCSyncService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class SyncTransactionWithOneC implements ShouldQueue
{
    use Queueable;

    public $transaction;
    /**
     * Create a new job instance.
     */

    public function __construct($transaction)
    {
        $this->transaction = $transaction;
    }

    /**
     * Execute the job.
     */
    public function handle(OneCSyncService $service)
    {
        $service->syncGiftCertificate([
            'transaction_id' => $this->transaction->id,
            'amount' => $this->transaction->amount,
            'type' => $this->transaction->type, // Например, "покупка" или "возврат"
        ]);
    }}
