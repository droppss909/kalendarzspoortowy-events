 <?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('attendees', static function (Blueprint $table) {
            if (!Schema::hasColumn('attendees', 'birth_date')) {
                $table->date('birth_date')->nullable()->after('last_name');
            }

            if (!Schema::hasColumn('attendees', 'age_category')) {
                $table->string('age_category', 10)->nullable()->after('birth_date');
            }
        });

        Schema::table('users', static function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'birth_date')) {
                $table->date('birth_date')->nullable()->after('timezone');
            }
        });
    }

    public function down(): void
    {
        Schema::table('attendees', static function (Blueprint $table) {
            if (Schema::hasColumn('attendees', 'age_category')) {
                $table->dropColumn('age_category');
            }
            if (Schema::hasColumn('attendees', 'birth_date')) {
                $table->dropColumn('birth_date');
            }
        });

        Schema::table('users', static function (Blueprint $table) {
            if (Schema::hasColumn('users', 'birth_date')) {
                $table->dropColumn('birth_date');
            }
        });
    }
};
