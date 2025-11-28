<?php

namespace App\Services;

use App\Models\AnalyticsEvent;

class AnalyticsService
{
    public function getEventStatistics($type, $startDate, $endDate)
    {
        return AnalyticsEvent::where('event_type', $type)
            ->whereBetween('created_at', [$startDate, $endDate])
            ->selectRaw('COUNT(*) as total, DATE(created_at) as date')
            ->groupBy('date')
            ->orderBy('date', 'asc')
            ->get();
    }

    /**
     * Получение детальной статистики по конкретным объектам (постам, сторис, баннерам)
     */
    public function getDetailedEventStatistics($type, $startDate, $endDate)
    {
        return AnalyticsEvent::where('event_type', $type)
            ->whereBetween('created_at', [$startDate, $endDate])
            ->whereNotNull('event_data')
            ->whereRaw("event_data->>'id' IS NOT NULL")
            ->selectRaw("
                event_data->>'id' as item_id,
                event_data->>'name' as item_name,
                COUNT(*) as views,
                MIN(created_at) as first_view,
                MAX(created_at) as last_view
            ")
            ->groupBy('item_id', 'item_name')
            ->orderBy('views', 'desc')
            ->limit(50)
            ->get();
    }

    public function getPromoCodeUsage($startDate, $endDate)
    {
        return AnalyticsEvent::where('event_type', 'promo_code_use')
            ->whereBetween('created_at', [$startDate, $endDate])
            ->selectRaw("event_data->>'promo_code' as promo_code, COUNT(*) as usage_count")
            ->groupBy('promo_code')
            ->orderBy('usage_count', 'desc')
            ->get();
    }
}
