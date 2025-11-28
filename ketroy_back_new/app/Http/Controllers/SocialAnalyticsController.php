<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\AnalyticsEvent;
use Illuminate\Support\Facades\Validator;

class SocialAnalyticsController extends Controller
{
    /**
     * @OA\Post(
     *     path="/analytics/social-click",
     *     summary="Записать клик по социальной сети",
     *     description="Отслеживание нажатий на кнопки социальных сетей (WhatsApp, Instagram, 2GIS)",
     *     tags={"Analytics"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"social_type", "source_page"},
     *             @OA\Property(property="social_type", type="string", example="whatsapp", description="Тип соцсети: whatsapp, instagram, 2gis"),
     *             @OA\Property(property="source_page", type="string", example="shop_detail", description="Страница источника: shop_detail, news_detail, nav_bar, partners"),
     *             @OA\Property(property="source_id", type="integer", example=123, description="ID объекта (магазина, новости)"),
     *             @OA\Property(property="source_name", type="string", example="Магазин Алматы", description="Название объекта"),
     *             @OA\Property(property="city", type="string", example="Алматы", description="Город пользователя"),
     *             @OA\Property(property="url", type="string", example="https://wa.me/77755390101", description="URL который открылся")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Событие успешно записано",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Social click tracked successfully")
     *         )
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Ошибка валидации"
     *     )
     * )
     */
    public function trackSocialClick(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'social_type' => 'required|string|in:whatsapp,instagram,2gis',
            'source_page' => 'required|string|in:shop_detail,news_detail,nav_bar,partners,certificate',
            'source_id' => 'nullable|integer',
            'source_name' => 'nullable|string|max:255',
            'city' => 'nullable|string|max:100',
            'url' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $userId = null;
        if ($request->user()) {
            $userId = $request->user()->id;
        }

        AnalyticsEvent::create([
            'event_type' => 'social_click',
            'user_id' => $userId,
            'event_data' => [
                'social_type' => $request->social_type,
                'source_page' => $request->source_page,
                'source_id' => $request->source_id,
                'source_name' => $request->source_name,
                'city' => $request->city,
                'url' => $request->url,
            ],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Social click tracked successfully'
        ]);
    }

    /**
     * @OA\Get(
     *     path="/admin/social-click-statistics",
     *     summary="Получить статистику кликов по социальным сетям",
     *     description="Детальная статистика по нажатиям на кнопки социальных сетей",
     *     tags={"Analytics"},
     *     security={{"bearerAuth":{}}},
     *     @OA\Parameter(
     *         name="start_date",
     *         in="query",
     *         description="Дата начала периода",
     *         required=false,
     *         @OA\Schema(type="string", format="date", example="2024-11-01")
     *     ),
     *     @OA\Parameter(
     *         name="end_date",
     *         in="query",
     *         description="Дата конца периода",
     *         required=false,
     *         @OA\Schema(type="string", format="date", example="2024-12-01")
     *     ),
     *     @OA\Parameter(
     *         name="social_type",
     *         in="query",
     *         description="Фильтр по типу соцсети",
     *         required=false,
     *         @OA\Schema(type="string", enum={"whatsapp", "instagram", "2gis"})
     *     ),
     *     @OA\Parameter(
     *         name="source_page",
     *         in="query",
     *         description="Фильтр по странице источника",
     *         required=false,
     *         @OA\Schema(type="string", enum={"shop_detail", "news_detail", "nav_bar", "partners", "certificate"})
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Статистика успешно получена"
     *     )
     * )
     */
    public function getSocialClickStatistics(Request $request)
    {
        $startDate = $request->get('start_date', now()->subMonth()->toDateString());
        $endDate = $request->get('end_date', now()->toDateString());
        $socialType = $request->get('social_type');
        $sourcePage = $request->get('source_page');

        // Добавляем конец дня к endDate для корректной выборки
        $startDateTime = $startDate . ' 00:00:00';
        $endDateTime = $endDate . ' 23:59:59';

        $query = AnalyticsEvent::where('event_type', 'social_click')
            ->whereBetween('created_at', [$startDateTime, $endDateTime]);

        if ($socialType) {
            $query->whereRaw("event_data->>'social_type' = ?", [$socialType]);
        }

        if ($sourcePage) {
            $query->whereRaw("event_data->>'source_page' = ?", [$sourcePage]);
        }

        // Общая статистика по соцсетям
        $bySocialType = AnalyticsEvent::where('event_type', 'social_click')
            ->whereBetween('created_at', [$startDateTime, $endDateTime])
            ->selectRaw("event_data->>'social_type' as social_type, COUNT(*) as clicks")
            ->groupBy('social_type')
            ->orderBy('clicks', 'desc')
            ->get();

        // Статистика по страницам источника
        $bySourcePage = AnalyticsEvent::where('event_type', 'social_click')
            ->whereBetween('created_at', [$startDateTime, $endDateTime])
            ->selectRaw("event_data->>'source_page' as source_page, COUNT(*) as clicks")
            ->groupBy('source_page')
            ->orderBy('clicks', 'desc')
            ->get();

        // Статистика по городам
        $byCity = AnalyticsEvent::where('event_type', 'social_click')
            ->whereBetween('created_at', [$startDateTime, $endDateTime])
            ->whereRaw("event_data->>'city' IS NOT NULL")
            ->whereRaw("event_data->>'city' != ''")
            ->selectRaw("event_data->>'city' as city, COUNT(*) as clicks")
            ->groupBy('city')
            ->orderBy('clicks', 'desc')
            ->get();

        // Детальная статистика: соцсеть + страница
        $detailed = AnalyticsEvent::where('event_type', 'social_click')
            ->whereBetween('created_at', [$startDateTime, $endDateTime])
            ->selectRaw("
                event_data->>'social_type' as social_type,
                event_data->>'source_page' as source_page,
                COUNT(*) as clicks
            ")
            ->groupBy('social_type', 'source_page')
            ->orderBy('clicks', 'desc')
            ->get();

        // Статистика по дням
        $byDate = AnalyticsEvent::where('event_type', 'social_click')
            ->whereBetween('created_at', [$startDateTime, $endDateTime])
            ->selectRaw("DATE(created_at) as date, COUNT(*) as clicks")
            ->groupBy('date')
            ->orderBy('date', 'asc')
            ->get();

        // Топ магазинов по кликам (если source_page = shop_detail)
        $topShops = AnalyticsEvent::where('event_type', 'social_click')
            ->whereBetween('created_at', [$startDateTime, $endDateTime])
            ->whereRaw("event_data->>'source_page' = 'shop_detail'")
            ->whereRaw("event_data->>'source_id' IS NOT NULL")
            ->selectRaw("
                event_data->>'source_id' as shop_id,
                event_data->>'source_name' as shop_name,
                COUNT(*) as clicks
            ")
            ->groupBy('shop_id', 'shop_name')
            ->orderBy('clicks', 'desc')
            ->limit(20)
            ->get();

        // Топ новостей по кликам WhatsApp (если source_page = news_detail)
        $topNews = AnalyticsEvent::where('event_type', 'social_click')
            ->whereBetween('created_at', [$startDateTime, $endDateTime])
            ->whereRaw("event_data->>'source_page' = 'news_detail'")
            ->whereRaw("event_data->>'source_id' IS NOT NULL")
            ->selectRaw("
                event_data->>'source_id' as news_id,
                event_data->>'source_name' as news_name,
                COUNT(*) as clicks
            ")
            ->groupBy('news_id', 'news_name')
            ->orderBy('clicks', 'desc')
            ->limit(20)
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'total_clicks' => $query->count(),
                'by_social_type' => $bySocialType,
                'by_source_page' => $bySourcePage,
                'by_city' => $byCity,
                'detailed' => $detailed,
                'by_date' => $byDate,
                'top_shops' => $topShops,
                'top_news' => $topNews,
            ],
            'period' => [
                'start_date' => $startDate,
                'end_date' => $endDate,
            ]
        ]);
    }
}

