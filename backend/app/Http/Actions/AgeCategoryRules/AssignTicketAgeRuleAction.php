<?php

declare(strict_types=1);

namespace HiEvents\Http\Actions\AgeCategoryRules;

use HiEvents\DomainObjects\EventDomainObject;
use HiEvents\Http\Actions\BaseAction;
use HiEvents\Http\Request\AgeCategoryRules\AssignTicketAgeRuleRequest;
use HiEvents\Http\ResponseCodes;
use HiEvents\Services\Application\Handlers\AgeCategoryRules\AssignTicketAgeRuleHandler;
use HiEvents\Services\Application\Handlers\AgeCategoryRules\DTO\AssignTicketAgeRuleDTO;
use Illuminate\Http\JsonResponse;

class AssignTicketAgeRuleAction extends BaseAction
{
    public function __construct(
        private readonly AssignTicketAgeRuleHandler $assignTicketAgeRuleHandler,
    )
    {
    }

    public function __invoke(AssignTicketAgeRuleRequest $request, int $eventId, int $ticketId): JsonResponse
    {
        $this->isActionAuthorized($eventId, EventDomainObject::class);

        $result = $this->assignTicketAgeRuleHandler->handle(
            AssignTicketAgeRuleDTO::fromArray(array_merge(
                $request->validated(),
                [
                    'event_id' => $eventId,
                    'ticket_id' => $ticketId,
                ]
            ))
        );

        return response()->json($result, ResponseCodes::HTTP_CREATED);
    }
}
