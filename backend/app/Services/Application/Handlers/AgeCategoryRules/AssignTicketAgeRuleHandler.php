<?php

declare(strict_types=1);

namespace HiEvents\Services\Application\Handlers\AgeCategoryRules;

use Carbon\CarbonImmutable;
use HiEvents\DomainObjects\Generated\ProductDomainObjectAbstract;
use HiEvents\Repository\Interfaces\ProductRepositoryInterface;
use HiEvents\Services\Application\Handlers\AgeCategoryRules\DTO\AssignTicketAgeRuleDTO;
use Illuminate\Database\ConnectionInterface;
use Illuminate\Support\Facades\DB;
use Symfony\Component\Routing\Exception\ResourceNotFoundException;

class AssignTicketAgeRuleHandler
{
    public function __construct(
        private readonly ProductRepositoryInterface $productRepository,
        private readonly ConnectionInterface $db,
    )
    {
    }

    /**
     * @return array{ticket_id:int, rule_id:int, rule:array, assigned_at:string}
     */
    public function handle(AssignTicketAgeRuleDTO $dto): array
    {
        $product = $this->productRepository->findFirstWhere([
            ProductDomainObjectAbstract::ID => $dto->ticket_id,
            ProductDomainObjectAbstract::EVENT_ID => $dto->event_id,
        ]);

        if ($product === null) {
            throw new ResourceNotFoundException(__('Ticket not found for this event.'));
        }

        return $this->db->transaction(function () use ($dto) {
            $ruleId = $this->getOrCreateRule($dto);
            $assignedAt = CarbonImmutable::now();

            DB::table('ticket_age_rule_assignment')->updateOrInsert(
                ['ticket_id' => $dto->ticket_id],
                [
                    'rule_id' => $ruleId,
                    'assigned_at' => $assignedAt,
                ]
            );

            $rule = DB::table('age_category_rules')->where('id', $ruleId)->first();

            return [
                'ticket_id' => $dto->ticket_id,
                'rule_id' => $ruleId,
                'assigned_at' => $assignedAt->toIso8601String(),
                'rule' => $rule !== null ? [
                    'id' => $rule->id,
                    'name' => $rule->name,
                    'calc_mode' => $rule->calc_mode,
                    'rule' => is_string($rule->rule) ? json_decode($rule->rule, true) : $rule->rule,
                    'version' => $rule->version,
                    'is_active' => (bool)$rule->is_active,
                    'created_at' => $rule->created_at,
                    'updated_at' => $rule->updated_at,
                ] : null,
            ];
        });
    }

    private function getOrCreateRule(AssignTicketAgeRuleDTO $dto): int
    {
        $existingRuleId = DB::table('age_category_rules')
            ->where('name', $dto->name)
            ->where('calc_mode', $dto->calc_mode)
            ->where('version', $dto->version)
            ->whereRaw('rule = ?::jsonb', [json_encode($dto->rule)])
            ->value('id');

        if ($existingRuleId !== null) {
            return (int)$existingRuleId;
        }

        return (int)DB::table('age_category_rules')->insertGetId([
            'name' => $dto->name,
            'calc_mode' => $dto->calc_mode,
            'rule' => json_encode($dto->rule),
            'version' => $dto->version,
            'is_active' => $dto->is_active,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
