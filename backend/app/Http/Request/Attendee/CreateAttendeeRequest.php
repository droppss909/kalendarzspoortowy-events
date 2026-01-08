<?php

namespace HiEvents\Http\Request\Attendee;

use HiEvents\Http\Request\BaseRequest;
use HiEvents\Locale;
use HiEvents\Validators\Rules\RulesHelper;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

class CreateAttendeeRequest extends BaseRequest
{
    protected function prepareForValidation(): void
    {
        if (Auth::check() && (!$this->has('birth_date') || $this->input('birth_date') === '')) {
            $user = Auth::user();

            if ($user !== null && $user->birth_date !== null && $user->birth_date !== '') {
                $this->merge(['birth_date' => $user->birth_date]);
            }
        }

        if (Auth::check() && (!$this->has('gender') || $this->input('gender') === '')) {
            $user = Auth::user();

            if ($user !== null && $user->gender !== null && $user->gender !== '') {
                $this->merge(['gender' => $user->gender]);
            }
        }
    }

    public function rules(): array
    {
        $isAuthenticated = Auth::check();
        
        return [
            'product_id' => ['int', 'required'],
            'product_price_id' => ['int', 'nullable', 'required'],
            'email' => $isAuthenticated ? ['nullable', 'email'] : ['required', 'email'],
            'first_name' => $isAuthenticated ? ['nullable', 'string', 'max:40'] : ['string', 'required', 'max:40'],
            'last_name' => ['string', 'max:40', 'nullable'],
            'birth_date' => ['required', 'date'],
            'age_category' => ['nullable', 'string', 'max:10'],
            'gender' => $isAuthenticated ? ['nullable', 'string', 'max:1', 'in:M,F'] : ['required', 'string', 'max:1', 'in:M,F'],
            'club_name' => ['required', 'string', 'max:150'],
            'amount_paid' => ['required', ...RulesHelper::MONEY],
            'send_confirmation_email' => ['required', 'boolean'],
            'taxes_and_fees' => ['array'],
            'taxes_and_fees.*.tax_or_fee_id' => ['required', 'int'],
            'taxes_and_fees.*.amount' => ['required', ...RulesHelper::MONEY],
            'locale' => $isAuthenticated ? ['nullable', Rule::in(Locale::getSupportedLocales())] : ['required', Rule::in(Locale::getSupportedLocales())],
        ];
    }
}
