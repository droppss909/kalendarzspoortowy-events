<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        $eventId = 1;

        DB::table('questions')
            ->where('event_id', $eventId)
            ->where('belongs_to', 'PRODUCT')
            ->update(['required' => false]);
    }

    public function down(): void
    {
        // No-op: required flags were relaxed intentionally.
    }
};
