<?php

namespace HiEvents\Services\Application\Handlers\Attendee\DTO;

use HiEvents\DataTransferObjects\Attributes\CollectionOf;
use HiEvents\DataTransferObjects\BaseDTO;
use Illuminate\Support\Collection;

class CreateAttendeeDTO extends BaseDTO
{
    public function __construct(
        public readonly string      $first_name,
        public readonly string      $last_name,
        public readonly string      $club_name,
        public readonly string      $email,
        public readonly int         $product_id,
        public readonly int         $event_id,
        public readonly bool        $send_confirmation_email,
        public readonly float       $amount_paid,
        public readonly string      $locale,
        public readonly ?string     $birth_date = null,
        public readonly ?string     $age_category = null,
        public readonly ?bool       $amount_includes_tax = false,
        public readonly ?int        $product_price_id = null,
        #[CollectionOf(CreateAttendeeTaxAndFeeDTO::class)]
        public readonly ?Collection $taxes_and_fees = null,

        // 🔥 NOWE POLE:
        public readonly ?int        $user_id = null,
    )
    {
    }
}
