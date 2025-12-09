<?php

declare(strict_types=1);

namespace HiEvents\Http\Actions\Users;

use HiEvents\Http\Actions\Auth\BaseAuthAction;
use HiEvents\Http\DTO\QueryParamsDTO;
use HiEvents\Resources\Event\EventResource;
use HiEvents\Services\Application\Handlers\Event\DTO\GetUserEventsDTO;
use HiEvents\Services\Application\Handlers\Event\GetUserEventsHandler;
use Illuminate\Http\JsonResponse;

class GetMyEventsAction extends BaseAuthAction
{
    public function __construct(
        private readonly GetUserEventsHandler $getUserEventsHandler
    )
    {
    }

    public function __invoke(): JsonResponse
    {
        $user = $this->getAuthenticatedUser();
        $queryParams = QueryParamsDTO::fromArray(request()->query->all());

        $events = $this->getUserEventsHandler->handle(
            new GetUserEventsDTO(
                userId: $user->getId(),
                queryParams: $queryParams,
            )
        );

        return $this->resourceResponse(
            resource: EventResource::class,
            data: $events,
        );
    }
}

