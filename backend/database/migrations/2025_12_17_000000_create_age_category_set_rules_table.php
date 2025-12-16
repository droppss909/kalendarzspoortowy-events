<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('age_category_set_rules', static function (Blueprint $table) {
            $table->id();
            $table->string('name', 255);
            $table->jsonb('rules');

            $table->foreignId('account_id')
                ->constrained('accounts')
                ->cascadeOnDelete();

            $table->timestamps();
            $table->softDeletes();
        });

        Schema::table('events', static function (Blueprint $table) {
            $table->foreignId('age_category_set_rule_id')
                ->nullable()
                ->after('category')
                ->constrained('age_category_set_rules')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('events', static function (Blueprint $table) {
            $table->dropForeign(['age_category_set_rule_id']);
            $table->dropColumn('age_category_set_rule_id');
        });

        Schema::dropIfExists('age_category_set_rules');
    }
};
