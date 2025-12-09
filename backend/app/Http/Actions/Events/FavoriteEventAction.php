<?php

declare(strict_types=1);

namespace HiEvents\Http\Actions\Events;

use HiEvents\DomainObjects\Generated\EventDomainObjectAbstract;
use HiEvents\DomainObjects\Status\EventStatus;
use HiEvents\Http\Actions\BaseAction;
use HiEvents\Http\ResponseCodes;
use HiEvents\Models\EventFavorite;
use HiEvents\Repository\Interfaces\EventRepositoryInterface;
use Illuminate\Http\JsonResponse;

class FavoriteEventAction extends BaseAction
{
    public function __construct(
        private readonly EventRepositoryInterface $eventRepository
    )
    {
    }

    public function __invoke(int $eventId): JsonResponse
    {
        $event = $this->eventRepository->findFirstWhere([
            EventDomainObjectAbstract::ID => $eventId,
            EventDomainObjectAbstract::STATUS => EventStatus::LIVE->name,
        ]);

        if (!$event) {
            return $this->notFoundResponse();
        }

        $favorite = EventFavorite::firstOrCreate([
            'user_id' => $this->getAuthenticatedUser()->getId(),
            'event_id' => $eventId,
        ]);

        $status = $favorite->wasRecentlyCreated ? ResponseCodes::HTTP_CREATED : ResponseCodes::HTTP_OK;

        return $this->jsonResponse([
            'event_id' => $eventId,
            'favorited' => true,
        ], $status);
    }
}
