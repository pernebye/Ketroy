<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Jobs\SendCustomPushNotificationJob;
use App\Models\PushNotification;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PushNotificationController extends Controller
{
    /**
     * Получить список всех push-уведомлений с пагинацией
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = $request->input('per_page', 15);
        $status = $request->input('status');
        $search = $request->input('search');

        $query = PushNotification::with('creator')
            ->orderByDesc('created_at');

        // Фильтр по статусу
        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        // Поиск по заголовку или тексту
        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'ILIKE', "%{$search}%")
                  ->orWhere('body', 'ILIKE', "%{$search}%");
            });
        }

        $notifications = $query->paginate($perPage);

        return response()->json($notifications);
    }

    /**
     * Получить одно push-уведомление
     */
    public function show($id): JsonResponse
    {
        $notification = PushNotification::with('creator')->findOrFail($id);
        
        // Добавляем подсчёт потенциальных получателей
        $notification->potential_recipients = $notification->countRecipients();
        
        return response()->json($notification);
    }

    /**
     * Создать новое push-уведомление
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'body' => 'required|string|max:2000',
            'scheduled_at' => 'nullable|date',
            'target_cities' => 'nullable|array',
            'target_cities.*' => 'string',
            'target_clothing_sizes' => 'nullable|array',
            'target_clothing_sizes.*' => 'string',
            'target_shoe_sizes' => 'nullable|array',
            'target_shoe_sizes.*' => 'string',
            'send_immediately' => 'boolean',
        ]);

        // Определяем статус
        $sendImmediately = $request->input('send_immediately', false);
        $status = PushNotification::STATUS_DRAFT;

        if ($sendImmediately) {
            $status = PushNotification::STATUS_SCHEDULED;
            $validated['scheduled_at'] = null; // null = отправить сразу
        } elseif (!empty($validated['scheduled_at'])) {
            $status = PushNotification::STATUS_SCHEDULED;
            // Конвертируем время из Asia/Almaty в UTC для хранения
            $validated['scheduled_at'] = Carbon::parse($validated['scheduled_at'], 'Asia/Almaty')
                ->setTimezone('UTC');
        }

        $notification = PushNotification::create([
            'title' => $validated['title'],
            'body' => $validated['body'],
            'status' => $status,
            'scheduled_at' => $validated['scheduled_at'] ?? null,
            'target_cities' => $validated['target_cities'] ?? null,
            'target_clothing_sizes' => $validated['target_clothing_sizes'] ?? null,
            'target_shoe_sizes' => $validated['target_shoe_sizes'] ?? null,
            'recipients_count' => 0,
            'created_by' => Auth::id(),
        ]);

        // Подсчитываем получателей
        $notification->recipients_count = $notification->countRecipients();
        $notification->save();

        // Если нужно отправить сразу - запускаем Job
        if ($sendImmediately) {
            SendCustomPushNotificationJob::dispatch($notification->id);
        }

        Log::info("Push notification created", [
            'id' => $notification->id,
            'status' => $status,
            'send_immediately' => $sendImmediately,
        ]);

        return response()->json([
            'message' => $sendImmediately 
                ? 'Уведомление создано и отправляется' 
                : 'Уведомление создано',
            'notification' => $notification->fresh('creator'),
        ], 201);
    }

    /**
     * Обновить push-уведомление (только если не отправлено)
     */
    public function update(Request $request, $id): JsonResponse
    {
        $notification = PushNotification::findOrFail($id);

        // Проверяем, можно ли редактировать
        if (!$notification->isEditable()) {
            return response()->json([
                'message' => 'Нельзя редактировать уже отправленное уведомление',
            ], 422);
        }

        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'body' => 'sometimes|string|max:2000',
            'scheduled_at' => 'nullable|date',
            'target_cities' => 'nullable|array',
            'target_cities.*' => 'string',
            'target_clothing_sizes' => 'nullable|array',
            'target_clothing_sizes.*' => 'string',
            'target_shoe_sizes' => 'nullable|array',
            'target_shoe_sizes.*' => 'string',
        ]);

        // Обновляем scheduled_at если передано
        if (array_key_exists('scheduled_at', $validated)) {
            if ($validated['scheduled_at']) {
                $validated['scheduled_at'] = Carbon::parse($validated['scheduled_at'], 'Asia/Almaty')
                    ->setTimezone('UTC');
                $validated['status'] = PushNotification::STATUS_SCHEDULED;
            } else {
                $validated['status'] = PushNotification::STATUS_DRAFT;
            }
        }

        $notification->update($validated);
        
        // Пересчитываем получателей
        $notification->recipients_count = $notification->countRecipients();
        $notification->save();

        return response()->json([
            'message' => 'Уведомление обновлено',
            'notification' => $notification->fresh('creator'),
        ]);
    }

    /**
     * Удалить push-уведомление (только если не отправлено/не отправляется)
     */
    public function destroy($id): JsonResponse
    {
        $notification = PushNotification::findOrFail($id);

        if (in_array($notification->status, [
            PushNotification::STATUS_SENDING,
            PushNotification::STATUS_SENT,
        ])) {
            return response()->json([
                'message' => 'Нельзя удалить уведомление, которое отправляется или уже отправлено',
            ], 422);
        }

        $notification->delete();

        return response()->json([
            'message' => 'Уведомление удалено',
        ]);
    }

    /**
     * Отправить уведомление немедленно
     */
    public function sendNow($id): JsonResponse
    {
        $notification = PushNotification::findOrFail($id);

        if (!in_array($notification->status, [
            PushNotification::STATUS_DRAFT,
            PushNotification::STATUS_SCHEDULED,
            PushNotification::STATUS_FAILED, // Можно повторить отправку
        ])) {
            return response()->json([
                'message' => 'Это уведомление уже отправлено или отправляется',
            ], 422);
        }

        $notification->update([
            'status' => PushNotification::STATUS_SCHEDULED,
            'scheduled_at' => null,
        ]);

        SendCustomPushNotificationJob::dispatch($notification->id);

        return response()->json([
            'message' => 'Уведомление поставлено в очередь на отправку',
        ]);
    }

    /**
     * Отменить запланированное уведомление
     */
    public function cancel($id): JsonResponse
    {
        $notification = PushNotification::findOrFail($id);

        if (!in_array($notification->status, [
            PushNotification::STATUS_DRAFT,
            PushNotification::STATUS_SCHEDULED,
        ])) {
            return response()->json([
                'message' => 'Это уведомление нельзя отменить',
            ], 422);
        }

        $notification->update([
            'status' => PushNotification::STATUS_CANCELLED,
        ]);

        return response()->json([
            'message' => 'Уведомление отменено',
        ]);
    }

    /**
     * Дублировать уведомление (создать копию)
     */
    public function duplicate($id): JsonResponse
    {
        $original = PushNotification::findOrFail($id);

        $copy = PushNotification::create([
            'title' => $original->title . ' (копия)',
            'body' => $original->body,
            'status' => PushNotification::STATUS_DRAFT,
            'scheduled_at' => null,
            'target_cities' => $original->target_cities,
            'target_clothing_sizes' => $original->target_clothing_sizes,
            'target_shoe_sizes' => $original->target_shoe_sizes,
            'recipients_count' => $original->countRecipients(),
            'created_by' => Auth::id(),
        ]);

        return response()->json([
            'message' => 'Копия уведомления создана',
            'notification' => $copy->fresh('creator'),
        ], 201);
    }

    /**
     * Получить статистику по уведомлениям
     */
    public function stats(): JsonResponse
    {
        $stats = [
            'total' => PushNotification::count(),
            'draft' => PushNotification::where('status', PushNotification::STATUS_DRAFT)->count(),
            'scheduled' => PushNotification::where('status', PushNotification::STATUS_SCHEDULED)->count(),
            'sent' => PushNotification::where('status', PushNotification::STATUS_SENT)->count(),
            'failed' => PushNotification::where('status', PushNotification::STATUS_FAILED)->count(),
            'cancelled' => PushNotification::where('status', PushNotification::STATUS_CANCELLED)->count(),
            'total_sent_count' => PushNotification::sum('sent_count'),
            'total_recipients' => PushNotification::sum('recipients_count'),
        ];

        return response()->json($stats);
    }

    /**
     * Получить доступные значения для таргетинга
     */
    public function getTargetingOptions(): JsonResponse
    {
        // Получаем города из справочника (cities.json)
        $citiesJson = \Illuminate\Support\Facades\Storage::disk('local')->get('cities.json');
        $citiesData = json_decode($citiesJson, true) ?? [];
        $cities = collect($citiesData)->pluck('name')->sort()->values();

        // Размеры одежды (46-64 с шагом 2, как в Flutter Constants)
        $clothingSizes = collect(range(46, 64, 2))->map(fn($size) => (string) $size);

        // Размеры обуви (39-46, как в Flutter Constants)
        $shoeSizes = collect(range(39, 46))->map(fn($size) => (string) $size);

        return response()->json([
            'cities' => $cities,
            'clothing_sizes' => $clothingSizes,
            'shoe_sizes' => $shoeSizes,
        ]);
    }

    /**
     * Пересчитать получателей для уведомления
     * Показывает только пользователей с АКТИВНЫМ device token (авторизованных на устройстве)
     */
    public function previewRecipients(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'target_cities' => 'nullable|array',
            'target_clothing_sizes' => 'nullable|array',
            'target_shoe_sizes' => 'nullable|array',
        ]);

        // Фильтруем только пользователей с активным device token
        $query = User::query()->whereHas('deviceTokens', function ($q) {
            $q->where('is_active', true);
        });

        if (!empty($validated['target_cities'])) {
            $query->whereIn('city', $validated['target_cities']);
        }

        if (!empty($validated['target_clothing_sizes'])) {
            $query->whereIn('clothing_size', $validated['target_clothing_sizes']);
        }

        if (!empty($validated['target_shoe_sizes'])) {
            $query->whereIn('shoe_size', $validated['target_shoe_sizes']);
        }

        $count = $query->count();

        return response()->json([
            'recipients_count' => $count,
        ]);
    }
}

