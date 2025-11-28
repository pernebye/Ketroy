<?php

namespace App\Http\Controllers;

use App\Models\Admin;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\Rule;

/**
 * @OA\Info(
 *     title="API документация Ketroy",
 *     version="1.0",
 *     description="Документация API для управления администраторами."
 * )
 */
class AdminAuthController extends Controller
{
    /**
     * @OA\Post(
     *     path="/admin/register",
     *     summary="Регистрация администратора",
     *     description="Создание новой учетной записи администратора.",
     *     tags={"Admin"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"name", "surname", "email", "password"},
     *             @OA\Property(property="name", type="string", example="John"),
     *             @OA\Property(property="surname", type="string", example="Doe"),
     *             @OA\Property(property="email", type="string", format="email", example="admin@example.com"),
     *             @OA\Property(property="password", type="string", format="password", example="password123"),
     *             @OA\Property(property="password_confirmation", type="string", format="password", example="password123")
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Регистрация успешна",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Регистрация успешна."),
     *             @OA\Property(property="token", type="string", example="generated_token"),
     *             @OA\Property(property="user", type="object",
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="name", type="string", example="John"),
     *                 @OA\Property(property="email", type="string", example="admin@example.com")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Ошибка валидации",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Ошибка валидации.")
     *         )
     *     )
     * )
     */
    public function register(Request $request): JsonResponse
    {
        $validatedData = $request->validate([
            'name' => 'required|string|max:255',
            'surname' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:admins',
            'role' => ['nullable', Rule::in(['super-admin', 'marketer'])],
            'password' => 'required|string|min:6|confirmed',
        ]);

        $admin = Admin::create([
            'name' => $validatedData['name'],
            'surname' => $validatedData['surname'],
            'email' => $validatedData['email'],
            'password' => Hash::make($validatedData['password']),
        ]);

        if ($validatedData['role'] != null) {
            $admin->assignRole($validatedData['role']);
        }

        return response()->json([
            'message' => 'Регистрация успешна.',
            'user' => $admin,
        ], 201);
    }

    /**
     * @OA\Post(
     *     path="/admin/login",
     *     summary="Вход администратора",
     *     description="Авторизация администратора с выдачей токена.",
     *     tags={"Admin"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"email", "password"},
     *             @OA\Property(property="email", type="string", format="email", example="admin@example.com"),
     *             @OA\Property(property="password", type="string", format="password", example="password123")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Авторизация успешна",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Авторизация успешна."),
     *             @OA\Property(property="token", type="string", example="generated_token"),
     *             @OA\Property(property="user", type="object",
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="name", type="string", example="John"),
     *                 @OA\Property(property="email", type="string", example="admin@example.com")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=401,
     *         description="Неверные учетные данные",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Неверные учетные данные")
     *         )
     *     )
     * )
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        $admin = Admin::where('email', $request->email)->first();

        if (!$admin || !Hash::check($request->password, $admin->password)) {
            return response()->json(['message' => 'Неверные учетные данные'], 401);
        }

        $token = $admin->createToken('admin-token')->plainTextToken;

        return response()->json([
            'message' => 'Авторизация успешна.',
            'token' => $token,
            'user' => $admin,
            'is_admin' => $admin->hasRole('super-admin'),
        ], 200);
    }

    /**
     * @OA\Post(
     *     path="/admin/logout",
     *     summary="Выход администратора",
     *     description="Выход администратора из системы с удалением токенов.",
     *     tags={"Admin"},
     *     security={{"sanctum": {}}},
     *     @OA\Response(
     *         response=200,
     *         description="Успешный выход",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Успешный выход")
     *         )
     *     )
     * )
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->tokens()->delete();

        return response()->json(['message' => 'Успешный выход'], 200);
    }
}
