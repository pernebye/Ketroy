<?php

namespace Database\Seeders;

use App\Models\User;
// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Database\Seeders\PermissionsSeeder;
use Database\Seeders\AnalyticsEventSeeder;
use Database\Seeders\RolesSeeder;
use Database\Seeders\ActualGroupSeeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            PermissionsSeeder::class,
            RolesSeeder::class,
            AnalyticsEventSeeder::class,
            ActualGroupSeeder::class,
        ]);
    }
}
