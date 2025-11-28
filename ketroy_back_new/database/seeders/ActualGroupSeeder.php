<?php

namespace Database\Seeders;

use App\Models\ActualGroup;
use App\Models\Story;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Storage;

class ActualGroupSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $sortOrder = 0;

        // 1. Сначала добавляем системные группы
        $systemGroups = [
            ['name' => 'Наши гости', 'is_system' => true],
            ['name' => 'Новинки', 'is_system' => true],
        ];

        foreach ($systemGroups as $group) {
            ActualGroup::updateOrCreate(
                ['name' => $group['name']],
                [
                    'is_system' => true,
                    'is_welcome' => false,
                    'sort_order' => $sortOrder++,
                ]
            );
        }

        // 2. Затем загружаем группы из JSON файла
        // Файл находится в storage/app/private/ (базовый путь local диска)
        $jsonPath = 'actual_groups.json';
        
        if (Storage::disk('local')->exists($jsonPath)) {
            $jsonContent = Storage::disk('local')->get($jsonPath);
            $jsonGroups = json_decode($jsonContent, true) ?? [];

            foreach ($jsonGroups as $group) {
                if (empty($group['name'])) continue;
                
                // Пропускаем если это системная группа (уже добавлена)
                if (in_array($group['name'], ['Наши гости', 'Новинки'])) continue;

                ActualGroup::updateOrCreate(
                    ['name' => $group['name']],
                    [
                        'image' => $group['image'] ?? null,
                        'is_welcome' => $group['is_welcome'] ?? false,
                        'is_system' => false,
                        'sort_order' => $sortOrder++,
                    ]
                );
            }

            $this->command->info('Загружено групп из JSON: ' . count($jsonGroups));
        } else {
            $this->command->warn('Файл actual_groups.json не найден');
        }

        // 3. Добавляем группы из существующих историй (если есть истории с группами, которых нет в списке)
        $existingGroupNames = ActualGroup::pluck('name')->toArray();
        $storyGroups = Story::select('actual_group')
            ->distinct()
            ->whereNotNull('actual_group')
            ->where('actual_group', '!=', '')
            ->pluck('actual_group')
            ->toArray();

        foreach ($storyGroups as $groupName) {
            if (!in_array($groupName, $existingGroupNames)) {
                ActualGroup::create([
                    'name' => $groupName,
                    'is_system' => false,
                    'is_welcome' => false,
                    'sort_order' => $sortOrder++,
                ]);
                $this->command->info('Добавлена группа из историй: ' . $groupName);
            }
        }

        $totalGroups = ActualGroup::count();
        $this->command->info("Всего групп в БД: {$totalGroups}");
    }
}

