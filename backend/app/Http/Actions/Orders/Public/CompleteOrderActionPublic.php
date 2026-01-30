<?php

declare(strict_types=1);

namespace HiEvents\Http\Actions\Orders\Public;

use HiEvents\Exceptions\ResourceConflictException;
use HiEvents\Http\Actions\BaseAction;
use HiEvents\Http\Request\Order\CompleteOrderRequest;
use HiEvents\Resources\Order\OrderResourcePublic;
use HiEvents\Services\Application\Handlers\Order\CompleteOrderHandler;
use HiEvents\Services\Application\Handlers\Order\DTO\CompleteOrderDTO;
use HiEvents\Services\Application\Handlers\Order\DTO\CompleteOrderOrderDTO;
use Illuminate\Http\JsonResponse;
use Symfony\Component\HttpFoundation\Response;

class CompleteOrderActionPublic extends BaseAction
{
    public function __construct(
        private readonly CompleteOrderHandler $orderService
    ) {
    }

    public function __invoke(CompleteOrderRequest $request, int $eventId, string $orderShortId): JsonResponse
    {
        try {
            $products = $request->input('products', []);

            if ($this->isUserAuthenticated()) {
                $userId = $this->getAuthenticatedUser()->getId();

                $products = array_map(
                    static fn (array $product): array => $product + ['user_id' => $userId],
                    $products
                );
            }

            $dto = CompleteOrderDTO::fromArray([
                'order' => CompleteOrderOrderDTO::fromArray([
                    'first_name' => $request->validated('order.first_name'),
                    'last_name'  => $request->validated('order.last_name'),
                    'club_name'  => $request->validated('order.club_name'),
                    'email'      => $request->validated('order.email'),
                    'address'    => $request->validated('order.address'),
                    'questions'  => $request->has('order.questions')
                        ? $request->input('order.questions')
                        : null,
                ]),
                'products' => $products,
            ]);

            $order = $this->orderService->handle($orderShortId, $dto);
        } catch (ResourceConflictException $e) {
            return $this->errorResponse($e->getMessage(), Response::HTTP_CONFLICT);
        }

        return $this->resourceResponse(OrderResourcePublic::class, $order);
    }
}
