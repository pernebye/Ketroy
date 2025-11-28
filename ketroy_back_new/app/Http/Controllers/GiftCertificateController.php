<?php

namespace App\Http\Controllers;

use App\Models\DeviceToken;
use Illuminate\Http\Request;
use App\Services\OneCApiService;
use App\Events\GiftCertificateCreated;
use App\Jobs\SyncTransactionWithOneC;
use App\Models\Purchase;
use App\Models\Transaction;
use App\Models\User;

class GiftCertificateController extends Controller
{
    /**
     * @OA\Post(
     *     path="/gifts/purchase",
     *     summary="Покупка подарочного сертификата",
     *     description="Обрабатывает покупку подарочного сертификата, создает сертификат в 1С и транзакцию для пользователя.",
     *     tags={"Purchases"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"phone", "amount"},
     *             @OA\Property(property="phone", type="string", example="79001234567"),
     *             @OA\Property(property="amount", type="number", format="float", example=200)
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Подарочный сертификат успешно куплен",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Gift certificate purchased successfully"),
     *             @OA\Property(property="certificate", type="object", example={
     *                 "certificate_code": "abc123xyz",
     *                 "amount": 200,
     *                 "phone": "79001234567"
     *             })
     *         )
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Ошибка валидации данных",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="The given data was invalid.")
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Неверный запрос",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Bad request")
     *         )
     *     )
     * )
     */
    public function purchase(Request $request)
    {
        $validated = $request->validate([
            'phone' => 'required|string',
            'amount' => 'required|numeric|min:100',
        ]);

        $recipient = User::where('phone', $request->phone)->first();
        if (!$recipient) {
            return response()->json(['message' => 'Получатель не найден в базе пользователей', NULL], 400);
        }

        // Создание сертификата в 1С
        // $certificate = $this->oneCApi->createGiftCertificate([
        //     'phone' => $validated['phone'],
        //     'amount' => $validated['amount'],
        // ]);

        $purchase = Purchase::create([
            'user_id' => $request->userId,
            'total_price' => $validated['amount'],
            'purchased_at' => now(),
        ]);


        Transaction::create([
            'user_id' => $request->userId,
            'type' => 'purchase',
            'amount' => $validated['amount'],
            'related_id' => $purchase->id,
            'related_type' => 'GiftCertificateController::purchase',
        ]);


        // Получаем активный токен получателя
        $activeToken = DeviceToken::getActiveTokenForUser($recipient->id);
        
        if (!empty($activeToken)) {
            event(new GiftCertificateCreated($activeToken, $request->amount));
        }
        return response()->json(['message' => 'Gift certificate purchased successfully', NULL], 200);
    }
}
