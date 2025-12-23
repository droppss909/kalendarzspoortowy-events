<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('event_age_rule_assignment', static function (Blueprint $table) {
            $table->foreignId('event_id')
                ->primary()
                ->constrained('events')
                ->cascadeOnDelete();

            $table->foreignId('rule_id')
                ->constrained('age_category_rules')
                ->restrictOnDelete();

            $table->timestampTz('assigned_at')->useCurrent();

            $table->index('rule_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('event_age_rule_assignment');
    }
};
