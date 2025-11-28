<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Admin;
use Illuminate\Http\Request;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;


class AdminController extends Controller
{
    /**
     * @OA\Post(
     *     path="/admin/change-role",
     *     summary="Назначение роли пользователю",
     *     description="Позволяет назначить роль для пользователя по его идентификатору.",
     *     tags={"User Management"},
     *     @OA\Parameter(
     *         name="userId",
     *         in="body",
     *         description="ID пользователя, которому назначается роль",
     *         required=true,
     *         @OA\Schema(
     *             type="integer",
     *             example=123
     *         )
     *     ),
     *      *     @OA\Parameter(
     *         name="role",
     *         in="body",
     *         description="Роль",
     *         required=true,
     *         @OA\Schema(
     *             type="string",
     *             example="admin, marketer"
     *         )
     *     ),
     *     @OA\Response(
     *         response=302,
     *         description="Пользователь успешно обновлен, перенаправление на список админов",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="User role assigned successfully")
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Пользователь не найден",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="User not found")
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Неверный запрос или параметры",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Invalid user ID")
     *         )
     *     )
     * )
     */
    public function changeRole(Request $request)
    {
        $user = Admin::find($request->userId);
        $user->roles()->detach();
        $user->assignRole($request->role);
        $user->save();
        $user->is_admin = $user->hasRole('super-admin');
        return response()->json($user);
    }

    public function getAdminInfo(Request $request)
    {
        $user = Admin::find($request->id);

        $user->is_admin = $user->hasRole('super-admin');


        return response()->json($user);
    }
}
