<?php

declare(strict_types=1);

namespace Tests\Feature\Http\Actions\AgeCategoryRules;

use Carbon\CarbonImmutable;
use HiEvents\Models\AccountConfiguration;
use HiEvents\Models\ProductCategory;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Config;
use Tests\TestCase;

class AssignTicketAgeRuleTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        AccountConfiguration::firstOrCreate(['id' => 1], [
            'id' => 1,
            'name' => 'Default',
            'is_system_default' => true,
            'application_fees' => [
                'percentage' => 1.5,
                'fixed' => 0,
            ],
        ]);

        Config::set('app.disable_registration', false);
    }

    public function test_user_can_assign_age_category_rule_to_ticket(): void
    {
        $password = 'Password123!';
        $registerResponse = $this->postJson('/auth/register', [
            'first_name' => 'Jane',
            'last_name' => 'Doe',
            'email' => 'jane@example.com',
            'password' => $password,
            'password_confirmation' => $password,
            'timezone' => 'UTC',
            'currency_code' => 'USD',
            'locale' => 'en',
            'birth_date' => '1990-01-01',
            'invite_token' => null,
        ]);

        $registerResponse->assertCreated();
        $token = $registerResponse->headers->get('X-Auth-Token');
        $headers = ['Authorization' => 'Bearer ' . $token];

        $organizerResponse = $this->postJson('/organizers', [
            'name' => 'Test Organizer',
            'email' => 'organizer@example.com',
            'timezone' => 'UTC',
            'currency' => 'USD',
            'description' => 'Desc',
            'phone' => null,
            'website' => null,
        ], $headers);

        $organizerResponse->assertCreated();
        $organizerId = $organizerResponse->json('data.id');

        $start = CarbonImmutable::now()->addDay();
        $end = $start->addDay();

        $eventResponse = $this->postJson('/events', [
            'title' => 'Test Event',
            'description' => 'Event description',
            'start_date' => $start->toDateTimeString(),
            'end_date' => $end->toDateTimeString(),
            'organizer_id' => $organizerId,
            'timezone' => 'UTC',
            'currency' => 'USD',
            'attributes' => [],
        ], $headers);

        $eventResponse->assertOk();
        $eventId = $eventResponse->json('data.id');

        $productCategory = ProductCategory::where('event_id', $eventId)->firstOrFail();

        $productResponse = $this->postJson("/events/{$eventId}/products", [
            'title' => 'VIP Ticket',
            'type' => 'PAID',
            'product_type' => 'TICKET',
            'product_category_id' => $productCategory->id,
            'prices' => [
                [
                    'price' => 50.00,
                    'label' => null,
                    'sale_start_date' => null,
                    'sale_end_date' => null,
                    'initial_quantity_available' => 100,
                    'is_hidden' => false,
                ],
            ],
            'order' => 1,
            'max_per_order' => 1,
            'min_per_order' => 0,
            'is_hidden' => false,
            'hide_before_sale_start_date' => false,
            'hide_after_sale_end_date' => false,
            'hide_when_sold_out' => false,
            'start_collapsed' => false,
            'show_quantity_remaining' => true,
            'is_hidden_without_promo_code' => false,
        ], $headers);

        $productResponse->assertCreated();
        $ticketId = $productResponse->json('data.id');

        $assignResponse = $this->postJson("/events/{$eventId}/products/{$ticketId}/age-category-rule", [
            'name' => 'U18/U23',
            'calc_mode' => 'BY_AGE',
            'rule' => [
                'bins' => [
                    ['min' => 0, 'max' => 17, 'label' => 'U18'],
                    ['min' => 18, 'max' => 23, 'label' => 'U23'],
                ],
            ],
            'version' => 1,
            'is_active' => true,
        ], $headers);

        $assignResponse->assertCreated();

        $assignResponse->assertJsonPath('ticket_id', $ticketId);
        $this->assertDatabaseHas('age_category_rules', [
            'name' => 'U18/U23',
            'calc_mode' => 'BY_AGE',
        ]);

        $ruleId = $assignResponse->json('rule_id');
        $this->assertDatabaseHas('ticket_age_rule_assignment', [
            'ticket_id' => $ticketId,
            'rule_id' => $ruleId,
        ]);
    }
}
