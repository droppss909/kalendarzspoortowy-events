<?php

namespace HiEvents\Http\Actions\Events;

use HiEvents\Models\Event;
use Illuminate\Http\JsonResponse;

class GetAllEventsPublicAction
{
    public function __invoke(): JsonResponse
    {
        // Jeśli event ma status "published" lub analogiczną flagę
        $events = Event::query()
            ->orderBy('start_date')
            ->get([
                'id',
                'title',
                'start_date',
                'end_date',
                'organizer_id',
                'location'
            ]);

        return response()->json([
            'data' => $events,
        ]);
    }
}
