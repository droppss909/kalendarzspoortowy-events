# Testowanie API zapisywania się na eventy

## Opis zmian

Dodano funkcjonalność, która pozwala zalogowanym użytkownikom zapisywać się na eventy bez konieczności podawania danych, które już mają w swoim koncie (email, first_name, last_name, locale).

### Zmiany w kodzie:

1. **CreateAttendeeRequest** - Pola `email`, `first_name`, `last_name`, `locale` są teraz opcjonalne dla zalogowanych użytkowników
2. **CreateAttendeeAction** - Automatycznie wypełnia dane z konta zalogowanego użytkownika, jeśli nie zostały podane w request

## Jak testować

### Metoda 1: Skrypt bash (curl)

```bash
cd backend
./test_attendee_api.sh [BASE_URL] [EMAIL] [PASSWORD] [EVENT_ID] [PRODUCT_ID] [PRODUCT_PRICE_ID]
```

Przykład:
```bash
./test_attendee_api.sh http://localhost:8000/api test@example.com password123 1 1 1
```

### Metoda 2: Ręczne testowanie z curl

#### 1. Logowanie i pobranie tokenu:

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

Z odpowiedzi skopiuj wartość `token`.

#### 2. Test 1: Tworzenie attendee BEZ podawania danych (automatyczne wypełnienie):

```bash
curl -X POST http://localhost:8000/api/events/1/attendees \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "product_id": 1,
    "product_price_id": 1,
    "amount_paid": 0.00,
    "send_confirmation_email": false,
    "taxes_and_fees": []
  }'
```

**Oczekiwany wynik:** Status 201, attendee utworzony z danymi z konta użytkownika.

#### 3. Test 2: Tworzenie attendee Z podaniem danych (nadpisanie):

```bash
curl -X POST http://localhost:8000/api/events/1/attendees \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "product_id": 1,
    "product_price_id": 1,
    "email": "custom.email@example.com",
    "first_name": "Custom",
    "last_name": "Name",
    "locale": "pl",
    "amount_paid": 0.00,
    "send_confirmation_email": false,
    "taxes_and_fees": []
  }'
```

**Oczekiwany wynik:** Status 201, attendee utworzony z podanymi danymi (nadpisują dane z konta).

#### 4. Test 3: Próba utworzenia attendee BEZ autoryzacji:

```bash
curl -X POST http://localhost:8000/api/events/1/attendees \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "product_id": 1,
    "product_price_id": 1,
    "amount_paid": 0.00,
    "send_confirmation_email": false,
    "taxes_and_fees": []
  }'
```

**Oczekiwany wynik:** Status 401 (Unauthorized) lub 422 (Validation Error) - wymaga autoryzacji lub wszystkich danych.

### Metoda 3: Testy jednostkowe (PHPUnit)

Możesz również stworzyć testy jednostkowe w `backend/tests/Feature/Attendees/`:

```php
<?php

namespace Tests\Feature\Attendees;

use HiEvents\Models\AccountConfiguration;
use HiEvents\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CreateAttendeeAuthenticatedTest extends TestCase
{
    use RefreshDatabase;

    public function setUp(): void
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
    }

    public function test_authenticated_user_can_create_attendee_without_providing_data(): void
    {
        $password = 'password123';
        $user = User::factory()->password($password)->withAccount()->create();
        
        // Login
        $loginResponse = $this->postJson('/auth/login', [
            'email' => $user->email,
            'password' => $password,
        ]);
        
        $token = $loginResponse->headers->get('X-Auth-Token');
        
        // Create event and product (setup required data)
        // ... (dodaj kod tworzący event i product)
        
        // Create attendee without providing email, first_name, etc.
        $response = $this->postJson("/api/events/1/attendees", [
            'product_id' => 1,
            'product_price_id' => 1,
            'amount_paid' => 0.00,
            'send_confirmation_email' => false,
            'taxes_and_fees' => [],
        ], [
            'Authorization' => 'Bearer ' . $token,
        ]);
        
        $response->assertStatus(201);
        
        $attendee = $response->json('data');
        $this->assertEquals($user->email, $attendee['email']);
        $this->assertEquals($user->first_name, $attendee['first_name']);
    }
}
```

## Wymagane dane

### Dla zalogowanych użytkowników (opcjonalne):
- `email` - automatycznie z konta
- `first_name` - automatycznie z konta
- `last_name` - automatycznie z konta (jeśli dostępne)
- `locale` - automatycznie z konta

### Zawsze wymagane:
- `product_id` - ID produktu/biletu
- `product_price_id` - ID ceny produktu
- `amount_paid` - Zapłacona kwota
- `send_confirmation_email` - Czy wysłać email potwierdzający
- `taxes_and_fees` - Tablica podatków i opłat (może być pusta)

## Uwagi

- Jeśli użytkownik poda własne dane, nadpiszą one dane z konta
- Dla niezalogowanych użytkowników wszystkie pola są nadal wymagane
- Endpoint wymaga autoryzacji (middleware `auth:api`)

