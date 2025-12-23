<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('age_category_rules', static function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('name');
            $table->string('calc_mode')->default('BY_AGE');
            $table->jsonb('rule');
            $table->integer('version')->default(1);
            $table->boolean('is_active')->default(true);
            $table->timestampsTz();

            $table->index('is_active');
        });

        // CHECK constraints validate the JSON structure and enforce the only supported calc_mode value.
        DB::unprepared("
            ALTER TABLE age_category_rules
            ADD CONSTRAINT age_category_rules_calc_mode_check CHECK (calc_mode = 'BY_AGE'),
            ADD CONSTRAINT age_category_rules_rule_has_bins CHECK (rule ? 'bins'),
            ADD CONSTRAINT age_category_rules_rule_bins_is_array CHECK (jsonb_typeof(rule->'bins') = 'array')
        ");

        DB::statement('CREATE INDEX age_category_rules_rule_path_ops ON age_category_rules USING gin (rule jsonb_path_ops)');
    }

    public function down(): void
    {
        Schema::dropIfExists('age_category_rules');
    }
};
