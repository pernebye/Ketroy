<?php

namespace App\Http\Controllers;

use App\Models\Notification;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * @OA\Get(
     *     path="/notifications",
     *     summary="Получение всех push-уведомлений пользователя",
     *     tags={"Notifications"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Response(
     *         response=200,
     *         description="Список уведомлений",
     *         @OA\JsonContent(
     *             type="array",
     *             @OA\Items(
     *                 @OA\Property(property="id", type="integer"),
     *                 @OA\Property(property="title", type="string"),
     *                 @OA\Property(property="body", type="string"),
     *                 @OA\Property(property="is_read", type="boolean"),
     *                 @OA\Property(property="created_at", type="string", format="date-time")
     *             )
     *         )
     *     )
     * )
     */
    public function index(Request $request): JsonResponse
    {
        // Лимит 100 уведомлений чтобы избежать проблем с большими JSON
        return response()->json($request->user()->notifications()->latest()->limit(100)->get());
    }

    /**
     * @OA\Delete(
     *     path="/notifications/{id}",
     *     summary="Удаление push-уведомления по ID",
     *     tags={"Notifications"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="ID уведомления",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=204,
     *         description="Уведомление удалено"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Уведомление не найдено"
     *     )
     * )
     */
    public function destroy(Request $request, $id): JsonResponse
    {
        $notification = $request->user()->notifications()->find($id);

        if (!$notification) {
            return response()->json(['message' => 'Уведомление не найдено'], 404);
        }

        $notification->delete();

        return response()->json([], 204);
    }

    public function deleteAllNotifications(Request $request): JsonResponse
    {
        $user = $request->user();

        $user->notifications()->delete();

        return response()->json(['message' => 'Все уведомления удалены!']);
    }

    /**
     * @OA\Post(
     *     path="/notifications/{id}/read",
     *     summary="Отметить уведомление как прочитанное",
     *     tags={"Notifications"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="ID уведомления",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Уведомление обновлено"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Уведомление не найдено"
     *     )
     * )
     */
    public function markAsRead(Request $request, $id): JsonResponse
    {
        $notification = $request->user()->notifications()->find($id);

        if (!$notification) {
            return response()->json(['message' => 'Уведомление не найдено'], 404);
        }

        $notification->update(['is_read' => true]);

        return response()->json(['message' => 'Уведомление отмечено как прочитанное']);
    }

    /**
     * Отметить ВСЕ уведомления как прочитанные (один запрос вместо 100+)
     */
    public function markAllAsRead(Request $request): JsonResponse
    {
        $count = $request->user()->notifications()
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json([
            'message' => 'Все уведомления отмечены как прочитанные',
            'count' => $count
        ]);
    }
}
