<?php

declare(strict_types=1);

namespace HiEvents\Http\Request\AgeCategoryRules;

use HiEvents\Http\Request\BaseRequest;
use Illuminate\Validation\Rule;

class AssignTicketAgeRuleRequest extends BaseRequest
{
    protected function prepareForValidation(): void
    {
        $this->merge([
            'calc_mode' => $this->input('calc_mode', 'BY_AGE'),
            'version' => $this->input('version', 1),
            'is_active' => $this->input('is_active', true),
        ]);
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'rule' => ['required', 'array'],
            'rule.bins' => ['required', 'array', 'min:1'],
            'calc_mode' => ['required', 'string', Rule::in(['BY_AGE'])],
            'version' => ['required', 'integer', 'min:1'],
            'is_active' => ['required', 'boolean'],
        ];
    }
}
