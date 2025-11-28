<?php

namespace App\Http\Controllers;

use App\Models\DeviceToken;
use App\Models\Gift;
use App\Models\User;
use App\Services\FirebaseService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;

class GiftController extends Controller
{
    protected FirebaseService $firebaseService;

    public function __construct(FirebaseService $firebaseService)
    {
        $this->firebaseService = $firebaseService;
    }

    /**
     * Получить список всех подарков для админки (вкладка "Выдача")
     */
    public function index(Request $request): JsonResponse
    {
        $query = Gift::with(['user', 'giftCatalog'])
            ->orderBy('created_at', 'desc');

        // Фильтр по статусу
        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        // Фильтр по пользователю
        if ($request->filled('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        // Поиск по имени пользователя или телефону
        if ($request->filled('search')) {
            $search = $request->search;
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('surname', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        $perPage = $request->input('per_page', 15);
        $gifts = $query->paginate($perPage);

        return response()->json($gifts);
    }

    /**
     * Получить подарки пользователя, ожидающие выбора (для мобильного приложения)
     * Возвращает группы подарков, которые пользователь может выбрать
     */
    public function getPendingGiftGroups(Request $request): JsonResponse
    {
        $user = $request->user();
        
        // Получаем все pending подарки пользователя, сгруппированные по gift_group_id
        $gifts = Gift::where('user_id', $user->id)
            ->where('status', Gift::STATUS_PENDING)
            ->orderBy('created_at', 'desc')
            ->get()
            ->groupBy('gift_group_id');

        $groups = [];
        foreach ($gifts as $groupId => $groupGifts) {
            $groups[] = [
                'gift_group_id' => $groupId,
                'gifts' => $groupGifts->map(function ($gift) {
                    return [
                        'id' => $gift->id,
                        'name' => $gift->name,
                        'image' => $gift->image,
                    ];
                }),
                'created_at' => $groupGifts->first()->created_at,
            ];
        }

        return response()->json([
            'groups' => $groups,
            'total_groups' => count($groups),
        ]);
    }

    /**
     * Активация подарка через QR-код магазина
     * Возвращает группу подарков для выбора
     */
    public function activateByQr(Request $request): JsonResponse
    {
        $user = $request->user();
        
        if (!$user) {
            return response()->json(['message' => 'Необходима авторизация'], 401);
        }

        // Получаем первую доступную группу подарков для выбора
        $pendingGift = Gift::where('user_id', $user->id)
            ->where('status', Gift::STATUS_PENDING)
            ->orderBy('created_at', 'asc')
            ->first();

        if (!$pendingGift) {
            return response()->json([
                'has_pending_gifts' => false,
                'message' => 'У вас нет подарков для активации'
            ]);
        }

        // Если у подарка нет gift_group_id (старые подарки), создаём его
        if (empty($pendingGift->gift_group_id)) {
            $pendingGift->gift_group_id = 'legacy_' . $pendingGift->id . '_' . time();
            $pendingGift->save();
        }

        // Получаем все подарки из этой группы
        $groupGifts = Gift::where('gift_group_id', $pendingGift->gift_group_id)
            ->where('status', Gift::STATUS_PENDING)
            ->get();

        return response()->json([
            'has_pending_gifts' => true,
            'gift_group_id' => $pendingGift->gift_group_id,
            'gifts' => $groupGifts->map(function ($gift) {
                return [
                    'id' => $gift->id,
                    'name' => $gift->name,
                    'image' => $gift->image,
                ];
            }),
            'message' => 'Выберите один из подарков!'
        ]);
    }

    /**
     * Выбор подарка пользователем (рандомный выбор из группы)
     * Вызывается после того как пользователь нажал на один из подарков
     */
    public function selectGift(Request $request): JsonResponse
    {
        $request->validate([
            'gift_group_id' => 'required|string',
        ]);

        $user = $request->user();
        
        // Получаем все подарки группы
        $groupGifts = Gift::where('gift_group_id', $request->gift_group_id)
            ->where('user_id', $user->id)
            ->where('status', Gift::STATUS_PENDING)
            ->get();

        if ($groupGifts->isEmpty()) {
            return response()->json([
                'message' => 'Подарки не найдены или уже выбраны'
            ], 404);
        }

        // Рандомно выбираем один подарок
        $selectedGift = $groupGifts->random();
        
        // Обновляем выбранный подарок
        $selectedGift->update([
            'status' => Gift::STATUS_SELECTED,
            'selected_at' => now(),
            'is_viewed' => true,
        ]);

        // Удаляем остальные подарки группы (они не были выбраны)
        Gift::where('gift_group_id', $request->gift_group_id)
            ->where('id', '!=', $selectedGift->id)
            ->delete();

        return response()->json([
            'message' => 'Поздравляем! Вы получили подарок!',
            'gift' => [
                'id' => $selectedGift->id,
                'name' => $selectedGift->name,
                'image' => $selectedGift->image,
            ]
        ]);
    }

    /**
     * Активация выбранного подарка (после выбора, перед выдачей)
     * Пользователь показывает QR-код продавцу
     */
    public function activateGift(Request $request): JsonResponse
    {
        $request->validate([
            'gift_id' => 'required|integer|exists:gifts,id',
        ]);

        $user = $request->user();
        $gift = Gift::findOrFail($request->gift_id);

        if ($gift->user_id !== $user->id) {
            return response()->json(['message' => 'Подарок не принадлежит вам'], 403);
        }

        if (!$gift->canBeActivated()) {
            return response()->json([
                'message' => 'Подарок не может быть активирован. Текущий статус: ' . $gift->status
            ], 400);
        }

        $gift->update([
            'status' => Gift::STATUS_ACTIVATED,
            'is_activated' => true,
        ]);

        return response()->json([
            'message' => 'Подарок активирован! Покажите экран продавцу для получения.',
            'gift' => $gift
        ]);
    }

    /**
     * Выдача подарка пользователю (вызывается из админки)
     */
    public function issueGift(Request $request, $id): JsonResponse
    {
        $gift = Gift::with('user')->findOrFail($id);

        if (!$gift->canBeIssued()) {
            return response()->json([
                'message' => 'Подарок не может быть выдан. Текущий статус: ' . $gift->status
            ], 400);
        }

        $gift->update([
            'status' => Gift::STATUS_ISSUED,
            'issued_at' => now(),
        ]);

        // Отправляем push-уведомление если пользователь авторизован на устройстве
        $user = $gift->user;
        $activeToken = $user ? DeviceToken::getActiveTokenForUser($user->id) : null;
        
        if ($user && !empty($activeToken)) {
            try {
                $this->firebaseService->sendPushNotification(
                    $gift->id,
                    1,
                    'gift_issued',
                    $activeToken,
                    '🎁 Подарок выдан!',
                    "Поздравляем! Ваш подарок \"{$gift->name}\" был успешно выдан. Спасибо за покупки в KETROY!"
                );
            } catch (\Exception $e) {
                Log::error('Failed to send gift issued notification', [
                    'gift_id' => $gift->id,
                    'user_id' => $user->id,
                    'error' => $e->getMessage()
                ]);
            }
        }

        return response()->json([
            'message' => 'Подарок успешно выдан',
            'gift' => $gift
        ]);
    }

    /**
     * Получить статистику по подаркам для админки
     */
    public function getStats(): JsonResponse
    {
        $stats = [
            'total' => Gift::count(),
            'pending' => Gift::pending()->count(),
            'selected' => Gift::selected()->count(),
            'activated' => Gift::activated()->count(),
            'issued' => Gift::issued()->count(),
        ];

        return response()->json($stats);
    }

    /**
     * Подтверждение выдачи подарка по QR-коду магазина
     * Вызывается из мобильного приложения после сканирования QR-кода у кассы
     */
    public function confirmIssuance(Request $request): JsonResponse
    {
        $request->validate([
            'gift_id' => 'required|integer|exists:gifts,id',
            'qr_code' => 'required|string',
        ]);

        $user = $request->user();
        $gift = Gift::with('user')->findOrFail($request->gift_id);

        // Проверяем что подарок принадлежит пользователю
        if ($gift->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Этот подарок не принадлежит вам'
            ], 403);
        }

        // Проверяем статус подарка - должен быть selected или activated
        if (!in_array($gift->status, [Gift::STATUS_SELECTED, Gift::STATUS_ACTIVATED])) {
            return response()->json([
                'success' => false,
                'message' => 'Подарок не готов к выдаче. Текущий статус: ' . $this->getStatusLabel($gift->status)
            ], 400);
        }

        // Валидация QR-кода (можно проверять формат, магазин и т.д.)
        // Для простоты сейчас принимаем любой непустой QR-код
        // В будущем можно добавить проверку на код магазина
        $qrCode = trim($request->qr_code);
        if (empty($qrCode)) {
            return response()->json([
                'success' => false,
                'message' => 'Неверный QR-код'
            ], 400);
        }

        // Обновляем статус подарка на выдан
        $gift->update([
            'status' => Gift::STATUS_ISSUED,
            'issued_at' => now(),
            'issuance_qr_code' => $qrCode, // Сохраняем QR-код для истории
        ]);

        // Отправляем push-уведомление если пользователь авторизован на устройстве
        $activeToken = DeviceToken::getActiveTokenForUser($user->id);
        
        if (!empty($activeToken)) {
            try {
                $this->firebaseService->sendPushNotification(
                    $gift->id,
                    1,
                    'gift_issued',
                    $activeToken,
                    '🎁 Подарок получен!',
                    "Поздравляем! Вы успешно получили подарок \"{$gift->name}\". Спасибо за покупки в KETROY!"
                );
            } catch (\Exception $e) {
                Log::error('Failed to send gift issuance notification', [
                    'gift_id' => $gift->id,
                    'user_id' => $user->id,
                    'error' => $e->getMessage()
                ]);
            }
        }

        Log::info('Gift issued via QR scan', [
            'gift_id' => $gift->id,
            'user_id' => $user->id,
            'qr_code' => $qrCode,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Подарок успешно получен!',
            'gift_id' => $gift->id,
            'gift' => [
                'id' => $gift->id,
                'name' => $gift->name,
                'image' => $gift->image,
                'status' => $gift->status,
            ]
        ]);
    }

    /**
     * Обновить статус подарка (из админки)
     * Поддерживает автоматический выбор подарка при переходе со статуса "pending"
     */
    public function updateStatus(Request $request, $id): JsonResponse
    {
        $request->validate([
            'status' => 'required|string|in:pending,selected,activated,issued',
            'auto_select_gift' => 'nullable|boolean',
        ]);

        $gift = Gift::with(['user', 'giftCatalog'])->findOrFail($id);
        $oldStatus = $gift->status;
        $newStatus = $request->input('status');

        // Получаем активный токен пользователя
        $activeToken = $gift->user ? DeviceToken::getActiveTokenForUser($gift->user->id) : null;
        
        // Если пытаемся установить статус "selected" или "issued" со статуса "pending"
        // и указан флаг auto_select_gift, то автоматически выбираем подарок
        if ($request->boolean('auto_select_gift') && $oldStatus === Gift::STATUS_PENDING) {
            $gift->update([
                'status' => $newStatus,
            ]);
            
            // Отправляем push-уведомление если пользователь авторизован на устройстве
            if ($gift->user && !empty($activeToken)) {
                try {
                    $this->firebaseService->sendPushNotification(
                        $gift->id,
                        1,
                        'gift_auto_selected',
                        $activeToken,
                        '🎁 Подарок автоматически выбран!',
                        "Администратор выбрал для вас подарок \"{$gift->name}\". Поздравляем!"
                    );
                } catch (\Exception $e) {
                    Log::error('Failed to send auto-select notification', [
                        'gift_id' => $gift->id,
                        'user_id' => $gift->user_id,
                        'error' => $e->getMessage()
                    ]);
                }
            }
        } else {
            // Обычное обновление статуса
            $gift->update([
                'status' => $newStatus,
            ]);
        }

        // Если новый статус "issued", отправляем push-уведомление
        if ($newStatus === Gift::STATUS_ISSUED && $gift->user && !empty($activeToken)) {
            try {
                $this->firebaseService->sendPushNotification(
                    $gift->id,
                    1,
                    'gift_issued',
                    $activeToken,
                    '🎁 Подарок выдан!',
                    "Поздравляем! Вам выдан подарок: {$gift->name}. Спасибо за покупки в KETROY!"
                );
            } catch (\Exception $e) {
                Log::error('Failed to send gift issued notification', [
                    'gift_id' => $gift->id,
                    'user_id' => $gift->user_id,
                    'error' => $e->getMessage()
                ]);
            }
        }

        Log::info('Gift status updated', [
            'gift_id' => $gift->id,
            'old_status' => $oldStatus,
            'new_status' => $newStatus,
            'auto_select' => $request->boolean('auto_select_gift'),
        ]);

        return response()->json([
            'message' => "Статус подарка изменен на '{$this->getStatusLabel($newStatus)}'",
            'data' => $gift->fresh(),
        ]);
    }

    /**
     * Отправить push-уведомление пользователю о подарке (вспомогательный метод)
     */
    public function sendNotification(Request $request, $id): JsonResponse
    {
        $request->validate([
            'title' => 'required|string|max:100',
            'message' => 'required|string|max:500',
        ]);

        $gift = Gift::with('user')->findOrFail($id);

        // Получаем активный токен пользователя
        $activeToken = $gift->user ? DeviceToken::getActiveTokenForUser($gift->user->id) : null;

        if (!$gift->user || empty($activeToken)) {
            return response()->json([
                'message' => 'Пользователь не имеет активного устройства для уведомлений'
            ], 400);
        }

        try {
            $this->firebaseService->sendPushNotification(
                $gift->id,
                1,
                'gift_notification',
                $activeToken,
                $request->input('title'),
                $request->input('message')
            );

            Log::info('Custom notification sent', [
                'gift_id' => $gift->id,
                'user_id' => $gift->user_id,
                'title' => $request->input('title'),
            ]);

            return response()->json([
                'message' => 'Уведомление успешно отправлено',
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send custom notification', [
                'gift_id' => $gift->id,
                'user_id' => $gift->user_id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'message' => 'Ошибка при отправке уведомления'
            ], 500);
        }
    }

    /**
     * Получить читаемый статус подарка
     */
    private function getStatusLabel(string $status): string
    {
        return match ($status) {
            Gift::STATUS_PENDING => 'Ожидает выбора',
            Gift::STATUS_SELECTED => 'Выбран',
            Gift::STATUS_ACTIVATED => 'Активирован',
            Gift::STATUS_ISSUED => 'Выдан',
            default => $status,
        };
    }
}


