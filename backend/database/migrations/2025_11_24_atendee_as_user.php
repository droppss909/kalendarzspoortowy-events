<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('attendees', function (Blueprint $table) {
            // nowa kolumna – opcjonalna (nullable)
            $table->unsignedBigInteger('user_id')
                ->nullable()
                ->after('id'); // albo w innym miejscu, jak wolisz

            $table->foreign('user_id', 'attendees_user_id_fk')
                ->references('id')
                ->on('users')
                ->onDelete('set null');

            $table->index('user_id', 'attendees_user_id_index');
        });
    }

    public function down(): void
    {
        Schema::table('attendees', function (Blueprint $table) {
            $table->dropIndex('attendees_user_id_index');
            $table->dropForeign('attendees_user_id_fk');
            $table->dropColumn('user_id');
        });
    }
};
