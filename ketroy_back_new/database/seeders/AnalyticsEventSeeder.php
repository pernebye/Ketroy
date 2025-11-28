<?php

namespace Database\Seeders;

use App\Models\AnalyticsEvent;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class AnalyticsEventSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        AnalyticsEvent::create(['event_type'=>'post']);
        AnalyticsEvent::create(['event_type'=>'story']);
        AnalyticsEvent::create(['event_type'=>'banner']);
        AnalyticsEvent::create(['event_type'=>'post']);
        AnalyticsEvent::create(['event_type'=>'post']);
        AnalyticsEvent::create(['event_type'=>'post']);
        AnalyticsEvent::create(['event_type'=>'story']);
        AnalyticsEvent::create(['event_type'=>'story']);
        AnalyticsEvent::create(['event_type'=>'story']);
        AnalyticsEvent::create(['event_type'=>'banner']);
        AnalyticsEvent::create(['event_type'=>'banner']);
        AnalyticsEvent::create(['event_type'=>'banner']);
    }
}
