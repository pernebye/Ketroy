<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class MigrateFromMysqlDump extends Command
{
    protected $signature = 'migrate:from-mysql 
                            {file : Path to MySQL dump file}
                            {--fresh : Drop all tables and re-run migrations before import}
                            {--skip-users : Skip users table (useful for production migration)}
                            {--dry-run : Parse dump without actually importing}';

    protected $description = 'Import data from MySQL dump file to PostgreSQL database';

    // Таблицы в порядке импорта (учитываем foreign keys)
    private array $tableOrder = [
        'admins',
        'users',
        'permissions',
        'roles',
        'model_has_roles',
        'role_has_permissions',
        'analytics_events',
        'banners',
        'bonus_programs',
        'news',
        'news_blocks',
        'shops',
        'shop_reviews',
        'stories',
        'promotions',
        'promotion_gifts',
        'gifts',
        'gift_certificates',
        'notifications',
        'promo_codes',
        'purchases',
        'referral_links',
        'transactions',
    ];

    // Таблицы которые не нужно импортировать
    private array $skipTables = [
        'migrations',
        'cache',
        'cache_locks',
        'jobs',
        'job_batches',
        'failed_jobs',
        'sessions',
        'personal_access_tokens',
        'password_reset_tokens',
    ];

    private array $stats = [];

    public function handle(): int
    {
        $filePath = $this->argument('file');
        
        if (!file_exists($filePath)) {
            $this->error("File not found: {$filePath}");
            return Command::FAILURE;
        }

        $this->info("🚀 Starting MySQL to PostgreSQL migration");
        $this->info("📂 Reading dump file: {$filePath}");

        // Fresh migration if requested
        if ($this->option('fresh')) {
            $this->warn("⚠️  Running fresh migration (dropping all tables)...");
            $this->call('migrate:fresh', ['--force' => true]);
        }

        // Parse the dump file
        $content = file_get_contents($filePath);
        $inserts = $this->parseInsertStatements($content);

        $this->info("📊 Found " . count($inserts) . " tables with data");

        if ($this->option('dry-run')) {
            $this->info("🔍 Dry run mode - showing parsed data:");
            foreach ($inserts as $table => $rows) {
                $this->line("  - {$table}: " . count($rows) . " rows");
            }
            return Command::SUCCESS;
        }

        // Import data in correct order
        $this->importData($inserts);

        // Reset sequences
        $this->resetSequences();

        // Show stats
        $this->showStats();

        $this->info("✅ Migration completed successfully!");

        return Command::SUCCESS;
    }

    private function parseInsertStatements(string $content): array
    {
        $inserts = [];
        
        // Find all INSERT INTO statements
        preg_match_all('/INSERT INTO `(\w+)` VALUES (.+?);/s', $content, $matches, PREG_SET_ORDER);

        foreach ($matches as $match) {
            $tableName = $match[1];
            $valuesString = $match[2];

            if (in_array($tableName, $this->skipTables)) {
                $this->line("  ⏭️  Skipping table: {$tableName}");
                continue;
            }

            if ($this->option('skip-users') && $tableName === 'users') {
                $this->line("  ⏭️  Skipping users table (--skip-users)");
                continue;
            }

            // Parse values
            $rows = $this->parseValues($valuesString);
            
            if (!empty($rows)) {
                $inserts[$tableName] = $rows;
            }
        }

        return $inserts;
    }

    private function parseValues(string $valuesString): array
    {
        $rows = [];
        $current = '';
        $depth = 0;
        $inString = false;
        $escape = false;

        for ($i = 0; $i < strlen($valuesString); $i++) {
            $char = $valuesString[$i];
            
            if ($escape) {
                $current .= $char;
                $escape = false;
                continue;
            }

            if ($char === '\\') {
                $current .= $char;
                $escape = true;
                continue;
            }

            if ($char === "'" && !$escape) {
                $inString = !$inString;
                $current .= $char;
                continue;
            }

            if (!$inString) {
                if ($char === '(') {
                    $depth++;
                    if ($depth === 1) {
                        $current = '';
                        continue;
                    }
                } elseif ($char === ')') {
                    $depth--;
                    if ($depth === 0) {
                        $rows[] = $this->parseRow($current);
                        $current = '';
                        continue;
                    }
                }
            }

            $current .= $char;
        }

        return $rows;
    }

    private function parseRow(string $rowString): array
    {
        $values = [];
        $current = '';
        $inString = false;
        $escape = false;

        for ($i = 0; $i < strlen($rowString); $i++) {
            $char = $rowString[$i];

            if ($escape) {
                // Handle MySQL escape sequences
                switch ($char) {
                    case 'n': $current .= "\n"; break;
                    case 'r': $current .= "\r"; break;
                    case 't': $current .= "\t"; break;
                    case '0': $current .= "\0"; break;
                    default: $current .= $char;
                }
                $escape = false;
                continue;
            }

            if ($char === '\\') {
                $escape = true;
                continue;
            }

            if ($char === "'" && !$escape) {
                $inString = !$inString;
                continue;
            }

            if (!$inString && $char === ',') {
                $values[] = $this->convertValue(trim($current));
                $current = '';
                continue;
            }

            $current .= $char;
        }

        // Don't forget the last value
        $values[] = $this->convertValue(trim($current));

        return $values;
    }

    private function convertValue(string $value): mixed
    {
        // NULL
        if ($value === 'NULL' || $value === '') {
            return null;
        }

        // Numbers
        if (is_numeric($value)) {
            if (strpos($value, '.') !== false) {
                return (float) $value;
            }
            return (int) $value;
        }

        // Boolean-like strings
        if ($value === '0' || $value === '1') {
            return (int) $value;
        }

        return $value;
    }

    private function importData(array $inserts): void
    {
        $this->info("\n📥 Importing data...\n");

        // First, disable foreign key checks for PostgreSQL
        DB::statement('SET session_replication_role = replica;');

        try {
            // Import in order
            foreach ($this->tableOrder as $tableName) {
                if (isset($inserts[$tableName])) {
                    $this->importTable($tableName, $inserts[$tableName]);
                    unset($inserts[$tableName]);
                }
            }

            // Import remaining tables (not in order)
            foreach ($inserts as $tableName => $rows) {
                $this->importTable($tableName, $rows);
            }
        } finally {
            // Re-enable foreign key checks
            DB::statement('SET session_replication_role = DEFAULT;');
        }
    }

    private function importTable(string $tableName, array $rows): void
    {
        if (!Schema::hasTable($tableName)) {
            $this->warn("  ⚠️  Table '{$tableName}' does not exist, skipping...");
            return;
        }

        $columns = Schema::getColumnListing($tableName);
        $successCount = 0;
        $errorCount = 0;

        // Clear existing data
        DB::table($tableName)->truncate();

        $progressBar = $this->output->createProgressBar(count($rows));
        $progressBar->setFormat("  Importing {$tableName}: %current%/%max% [%bar%] %percent:3s%%");

        foreach ($rows as $rowValues) {
            try {
                // Map values to columns
                $data = [];
                foreach ($columns as $index => $column) {
                    if (isset($rowValues[$index])) {
                        $data[$column] = $rowValues[$index];
                    }
                }

                // Convert boolean fields for PostgreSQL
                $data = $this->convertBooleans($tableName, $data);

                DB::table($tableName)->insert($data);
                $successCount++;
            } catch (\Exception $e) {
                $errorCount++;
                if ($this->output->isVerbose()) {
                    $this->error("\n    Error: " . $e->getMessage());
                }
            }

            $progressBar->advance();
        }

        $progressBar->finish();
        $this->newLine();

        $this->stats[$tableName] = [
            'success' => $successCount,
            'errors' => $errorCount,
        ];

        if ($errorCount > 0) {
            $this->warn("    ⚠️  {$errorCount} errors occurred");
        }
    }

    private function convertBooleans(string $tableName, array $data): array
    {
        $booleanFields = [
            'banners' => ['is_active'],
            'news' => [],
            'stories' => ['is_active'],
            'shops' => ['is_active'],
            'users' => ['referral_applied', 'is_deleted'],
            'gifts' => ['is_activated', 'is_visible'],
            'notifications' => ['is_read'],
            'promotions' => ['is_active'],
        ];

        if (isset($booleanFields[$tableName])) {
            foreach ($booleanFields[$tableName] as $field) {
                if (isset($data[$field])) {
                    $data[$field] = (bool) $data[$field];
                }
            }
        }

        return $data;
    }

    private function resetSequences(): void
    {
        $this->info("\n🔄 Resetting PostgreSQL sequences...");

        $tables = array_merge($this->tableOrder, array_keys($this->stats));
        $tables = array_unique($tables);

        foreach ($tables as $tableName) {
            if (!Schema::hasTable($tableName)) {
                continue;
            }

            try {
                // Get the max ID
                $maxId = DB::table($tableName)->max('id');
                
                if ($maxId) {
                    $sequenceName = "{$tableName}_id_seq";
                    DB::statement("SELECT setval('{$sequenceName}', {$maxId}, true)");
                    $this->line("  ✅ Reset sequence for {$tableName} to {$maxId}");
                }
            } catch (\Exception $e) {
                // Table might not have id column or sequence
                if ($this->output->isVerbose()) {
                    $this->line("  ⏭️  Skipped {$tableName}: no sequence");
                }
            }
        }
    }

    private function showStats(): void
    {
        $this->newLine();
        $this->info("📊 Import Statistics:");
        $this->newLine();

        $headers = ['Table', 'Imported', 'Errors'];
        $rows = [];

        $totalSuccess = 0;
        $totalErrors = 0;

        foreach ($this->stats as $table => $stat) {
            $rows[] = [
                $table,
                $stat['success'],
                $stat['errors'] > 0 ? "<fg=red>{$stat['errors']}</>" : '0',
            ];
            $totalSuccess += $stat['success'];
            $totalErrors += $stat['errors'];
        }

        $this->table($headers, $rows);
        
        $this->info("Total: {$totalSuccess} records imported, {$totalErrors} errors");
    }
}







