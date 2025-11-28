<?php

namespace App\Http\Controllers;

use App\Events\BonusUpdated;
use App\Models\Gift;
use App\Models\Promotion;
use App\Models\Purchase;
use App\Models\Transaction;
use App\Models\User;
use App\Services\OneCApiService;
use App\Services\LoyaltyLevelService;
use App\Services\ReferralService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use App\Services\GiftService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;


class TransactionController extends Controller
{
    protected OneCApiService $oneCApi;
    protected LoyaltyLevelService $loyaltyService;
    protected ReferralService $referralService;

    public function __construct(
        OneCApiService $oneCApi, 
        LoyaltyLevelService $loyaltyService,
        ReferralService $referralService
    ) {
        $this->oneCApi = $oneCApi;
        $this->loyaltyService = $loyaltyService;
        $this->referralService = $referralService;
    }

    public function processTransactions(Request $request, GiftService $giftService): JsonResponse
    {
        // Логируем входящие данные для отладки
        Log::info('[Transaction] Incoming webhook', [
            'data_count' => count($request->data ?? []),
            'data' => $request->data
        ]);
        
        $request->validate([
            'data' => 'required|array',
            'data.*.userId' => 'required|string',
            'data.*.operation' => 'required|string|in:add,write-off',
            'data.*.purchaseAmount' => 'required|integer',
            'data.*.bonusAmount' => 'required|integer',
            'data.*.bonusAccrualDate' => 'required|date_format:Y-m-d\TH:i:s'
        ]);

        $processedCount = 0;
        $loyaltyUpdates = [];
        $processedDocuments = []; // Для дедупликации по documentId + operation

        foreach ($request->data as $transactionData) {
            // Пропускаем записи с нулевой суммой бонусов
            if (empty($transactionData['bonusAmount']) || $transactionData['bonusAmount'] <= 0) {
                Log::info('[Transaction] Skipping zero bonus amount', $transactionData);
                continue;
            }
            
            // Дедупликация в рамках одного запроса
            $documentId = $transactionData['documentId'] ?? null;
            $dedupeKey = $documentId . '_' . $transactionData['operation'];
            if ($documentId && isset($processedDocuments[$dedupeKey])) {
                Log::info('[Transaction] Skipping duplicate in request: ' . $dedupeKey);
                continue;
            }
            $processedDocuments[$dedupeKey] = true;
            
            // Дедупликация между запросами (кэш на 60 секунд)
            // Это защита от двойного вызова подписки в 1С
            $cacheKey = 'transaction_' . $dedupeKey;
            if ($documentId && Cache::has($cacheKey)) {
                Log::info('[Transaction] Skipping duplicate from cache: ' . $dedupeKey);
                continue;
            }
            if ($documentId) {
                Cache::put($cacheKey, true, 60); // 60 секунд
            }
            
            $user = User::where('phone', mb_substr($transactionData['userId'], 1))->first();

            if (!$user) {
                Log::info('[Transaction] User not found for phone: ' . $transactionData['userId']);
                continue;
            }

            // Сохраняем withDelay в кэш для UserObserver (чтобы формировать правильный текст push)
            $withDelay = $transactionData['withDelay'] ?? false;
            Cache::put('bonus_with_delay_' . $user->id, $withDelay, 60);

            // Обновляем бонусы пользователя
            // Push-уведомление отправляется автоматически через UserObserver
            if ($transactionData['operation'] === 'add') {
                $user->increment('bonus_amount', $transactionData['bonusAmount']);
            } else {
                $user->decrement('bonus_amount', $transactionData['bonusAmount']);
            }
            
            $purchase = null;

            if ($transactionData['operation'] === "add") {
                $purchase = Purchase::create([
                    'user_id' => $user->id,
                    'total_price' => $transactionData['purchaseAmount'],
                    'purchased_at' => Carbon::parse($transactionData['bonusAccrualDate'])->subDays(14),
                ]);

                // Получаем общую сумму покупок пользователя
                $totalPurchases = Purchase::where('user_id', $user->id)->sum('total_price');

                // Обрабатываем геймификацию / уровни лояльности
                try {
                    $loyaltyResult = $this->loyaltyService->processPurchase(
                        $user,
                        $totalPurchases // Передаём общую сумму покупок для проверки уровней
                    );
                    
                    if (!empty($loyaltyResult['levels_granted'])) {
                        $loyaltyUpdates[] = [
                            'user_id' => $user->id,
                            'new_levels' => array_map(fn($l) => $l->name, $loyaltyResult['levels_granted'])
                        ];
                    }
                } catch (\Exception $e) {
                    Log::error('[Transaction] Loyalty processing failed for user ' . $user->id . ': ' . $e->getMessage());
                }
            }

            Transaction::create([
                'user_id' => $user->id,
                'type' => $transactionData['operation'],
                'amount' => $transactionData['purchaseAmount'],
                'related_id' => $purchase ? $purchase->id : null
            ]);

            // Обрабатываем реферальную программу
            if ($user->referrer_id && $user->used_promo_code) {
                try {
                    $this->referralService->processReferralPurchase($user, $transactionData['purchaseAmount']);
                } catch (\Exception $e) {
                    Log::error('[Transaction] Referral processing failed: ' . $e->getMessage());
                }
            }

            $processedCount++;
        }

        Log::info('[Transaction] Processed ' . $processedCount . ' transactions');
        
        if (!empty($loyaltyUpdates)) {
            Log::info('[Transaction] Loyalty level updates: ' . json_encode($loyaltyUpdates));
        }

        return response()->json([
            'message' => 'Success',
            'processed' => $processedCount,
            'loyalty_updates' => count($loyaltyUpdates)
        ], 200);
    }
}
