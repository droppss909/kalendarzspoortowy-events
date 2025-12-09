<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('event_favorites', static function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('event_id')->constrained()->onDelete('cascade');

            $table->timestamps();
            $table->softDeletes();

            $table->index('user_id');
            $table->index('event_id');
            $table->unique(['user_id', 'event_id', 'deleted_at'], 'event_favorites_user_event_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('event_favorites');
    }
};
