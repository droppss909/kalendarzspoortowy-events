<?php

declare(strict_types=1);

namespace HiEvents\Http\Actions\Users;

use HiEvents\Http\Actions\Auth\BaseAuthAction;
use HiEvents\Http\DTO\QueryParamsDTO;
use HiEvents\Resources\Event\EventResource;
use HiEvents\Services\Application\Handlers\Event\DTO\GetUserEventsDTO;
use HiEvents\Services\Application\Handlers\Event\GetUserEventsHandler;
use HiEvents\DomainObjects\Status\OrderPaymentStatus;
use HiEvents\DomainObjects\Status\OrderStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

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

        $stats = DB::table('attendees')
            ->join('orders', 'orders.id', '=', 'attendees.order_id')
            ->where('attendees.user_id', $user->getId())
            ->whereNull('attendees.deleted_at')
            ->whereIn('orders.status', [
                OrderStatus::COMPLETED->name,
                OrderStatus::AWAITING_OFFLINE_PAYMENT->name,
                OrderStatus::RESERVED->name,
            ])
            ->selectRaw('count(distinct attendees.event_id) as total_events')
            ->selectRaw(
                'count(distinct case when orders.payment_status in (?, ?) then attendees.event_id end) as paid_events',
                [OrderPaymentStatus::PAYMENT_RECEIVED->name, OrderPaymentStatus::NO_PAYMENT_REQUIRED->name]
            )
            ->selectRaw(
                'count(distinct case when orders.payment_status in (?, ?, ?) then attendees.event_id end) as unpaid_events',
                [
                    OrderPaymentStatus::AWAITING_PAYMENT->name,
                    OrderPaymentStatus::AWAITING_OFFLINE_PAYMENT->name,
                    OrderPaymentStatus::PAYMENT_FAILED->name,
                ]
            )
            ->first();

        return $this->resourceResponse(
            resource: EventResource::class,
            data: $events,
            meta: [
                'user_event_stats' => [
                    'total_events' => (int) ($stats->total_events ?? 0),
                    'paid_events' => (int) ($stats->paid_events ?? 0),
                    'unpaid_events' => (int) ($stats->unpaid_events ?? 0),
                ],
            ],
        );
    }
}
