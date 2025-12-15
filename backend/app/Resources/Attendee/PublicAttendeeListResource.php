<?php

namespace HiEvents\Resources\Attendee;

use HiEvents\DomainObjects\AttendeeDomainObject;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin AttendeeDomainObject
 */
class PublicAttendeeListResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'first_name' => $this->getFirstName(),
            'last_name' => $this->getLastName(),
            'club_name' => $this->getClubName(),
            'age_category' => null, // placeholder for future age category
        ];
    }
}
