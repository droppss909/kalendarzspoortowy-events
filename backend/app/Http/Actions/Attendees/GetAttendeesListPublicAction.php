<?php

declare(strict_types=1);

namespace HiEvents\Http\Actions\Attendees;

use HiEvents\Http\Actions\BaseAction;
use HiEvents\Repository\Interfaces\AttendeeRepositoryInterface;
use HiEvents\Resources\Attendee\PublicAttendeeListResource;
use Illuminate\Http\JsonResponse;

class GetAttendeesListPublicAction extends BaseAction
{
    public function __construct(
        private readonly AttendeeRepositoryInterface $attendeeRepository,
    )
    {
    }

    public function __invoke(int $eventId): JsonResponse
    {
        $attendees = $this->attendeeRepository->findByEventIdForExport($eventId);

        return $this->resourceResponse(
            resource: PublicAttendeeListResource::class,
            data: $attendees,
        );
    }
}
