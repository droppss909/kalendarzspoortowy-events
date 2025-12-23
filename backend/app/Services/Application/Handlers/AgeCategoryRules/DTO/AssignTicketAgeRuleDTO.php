<?php

declare(strict_types=1);

namespace HiEvents\Services\Application\Handlers\AgeCategoryRules\DTO;

use HiEvents\DataTransferObjects\BaseDTO;

class AssignTicketAgeRuleDTO extends BaseDTO
{
    public function __construct(
        public readonly int   $event_id,
        public readonly int   $ticket_id,
        public readonly string $name,
        public readonly array $rule,
        public readonly string $calc_mode = 'BY_AGE',
        public readonly int $version = 1,
        public readonly bool $is_active = true,
    )
    {
    }
}
