<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;


class RolesSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
    $superAdminRole = Role::firstOrCreate(['name' => 'super-admin']);
    $marketerRole = Role::firstOrCreate(['name' => 'marketer']);

    // Разрешения для супер-админа
    $superAdminRole->givePermissionTo(Permission::all());

    // Разрешения для маркетолога
    $marketerRole->givePermissionTo([
        'view content',
        'manage content',
        'view analytics',
    ]);
    }
}
