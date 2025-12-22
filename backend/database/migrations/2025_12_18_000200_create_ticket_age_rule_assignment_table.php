<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('ticket_age_rule_assignment', static function (Blueprint $table) {
            $table->foreignId('ticket_id')
                ->primary()
                ->constrained('tickets')
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
        Schema::dropIfExists('ticket_age_rule_assignment');
    }
};
