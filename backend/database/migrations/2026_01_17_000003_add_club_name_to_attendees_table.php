<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (!Schema::hasColumn('attendees', 'club_name')) {
            Schema::table('attendees', static function (Blueprint $table) {
                $table->string('club_name', 150)->nullable()->after('last_name');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('attendees', 'club_name')) {
            Schema::table('attendees', static function (Blueprint $table) {
                $table->dropColumn('club_name');
            });
        }
    }
};
