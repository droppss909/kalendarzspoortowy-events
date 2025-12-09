<?php

declare(strict_types=1);

namespace HiEvents\Services\Application\Handlers\Event\DTO;

use HiEvents\DataTransferObjects\BaseDTO;
use HiEvents\Http\DTO\QueryParamsDTO;

class GetUserEventsDTO extends BaseDTO
{
    public function __construct(
        public readonly int $userId,
        public readonly QueryParamsDTO $queryParams,
    )
    {
    }
}

