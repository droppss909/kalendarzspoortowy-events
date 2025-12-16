<?php

namespace HiEvents\Http\Actions\Attendees;

use HiEvents\DomainObjects\EventDomainObject;
use HiEvents\Exceptions\InvalidProductPriceId;
use HiEvents\Exceptions\NoTicketsAvailableException;
use HiEvents\Http\Actions\BaseAction;
use HiEvents\Http\Request\Attendee\CreateAttendeeRequest;
use HiEvents\Http\ResponseCodes;
use HiEvents\Resources\Attendee\AttendeeResource;
use HiEvents\Services\Application\Handlers\Attendee\CreateAttendeeHandler;
use HiEvents\Services\Application\Handlers\Attendee\DTO\CreateAttendeeDTO;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;
use Throwable;

class CreateAttendeeAction extends BaseAction
{
    private CreateAttendeeHandler $createAttendeeHandler;

    public function __construct(CreateAttendeeHandler $createAttendeeHandler)
    {
        $this->createAttendeeHandler = $createAttendeeHandler;
    }

    /**
     * @throws ValidationException|Throwable
     */
    public function __invoke(CreateAttendeeRequest $request, int $eventId): JsonResponse
    {
        $this->isActionAuthorized($eventId, EventDomainObject::class);

        $validationData = $request->validationData();
        
        // Jeśli użytkownik jest zalogowany, automatycznie wypełnij dane z jego konta
        if ($this->isUserAuthenticated()) {
            $user = $this->getAuthenticatedUser();
            
            // Wypełnij dane tylko jeśli nie zostały podane w request
            // Używamy isset() i sprawdzamy czy wartość nie jest pusta
            if (!isset($validationData['email']) || $validationData['email'] === '') {
                $validationData['email'] = $user->getEmail();
            }
            if (!isset($validationData['first_name']) || $validationData['first_name'] === '') {
                $validationData['first_name'] = $user->getFirstName();
            }
            if ((!isset($validationData['last_name']) || $validationData['last_name'] === '') && $user->getLastName()) {
                $validationData['last_name'] = $user->getLastName();
            }
            if (!isset($validationData['locale']) || $validationData['locale'] === '') {
                $validationData['locale'] = $user->getLocale();
            }
            if (!isset($validationData['birth_date']) || $validationData['birth_date'] === '') {
                $validationData['birth_date'] = $user->getBirthDate();
            }
        }

        try {
            $attendee = $this->createAttendeeHandler->handle(
                CreateAttendeeDTO::fromArray(
                    array_merge(
                        $validationData,
                        [
                            'event_id' => $eventId,
                            // 🔥 Nowe pole: przypisujemy user_id, jeśli jest zalogowany
                            'user_id' => $this->isUserAuthenticated() ? $this->getAuthenticatedUser()->getId() : null,
                        ]
                    )
                )
            );
        } catch (NoTicketsAvailableException $exception) {
            throw ValidationException::withMessages([
                'product_id' => $exception->getMessage(),
            ]);
        } catch (InvalidProductPriceId $exception) {
            throw ValidationException::withMessages([
                'product_price_id' => $exception->getMessage(),
            ]);
        }

        return $this->resourceResponse(
            resource: AttendeeResource::class,
            data: $attendee,
            statusCode: ResponseCodes::HTTP_CREATED
        );
    }

}
