<?php

/**
 * Skrypt do testowania API zapisywania się na eventy
 * 
 * Użycie:
 *   php test_attendee_api.php [email] [password] [event_id] [product_id] [product_price_id]
 * 
 * Przykład:
 *   php test_attendee_api.php test@example.com password123 1 1 1
 */

require __DIR__ . '/vendor/autoload.php';

use Illuminate\Support\Facades\Http;

// Parametry
$baseUrl = getenv('API_BASE_URL') ?: 'http://localhost:8000/api';
$email = $argv[1] ?? 'test@example.com';
$password = $argv[2] ?? 'password';
$eventId = $argv[3] ?? 1;
$productId = $argv[4] ?? 1;
$productPriceId = $argv[5] ?? 1;

echo "=== Test API zapisywania się na eventy ===\n";
echo "Base URL: $baseUrl\n";
echo "Email: $email\n";
echo "Event ID: $eventId\n";
echo "Product ID: $productId\n";
echo "Product Price ID: $productPriceId\n\n";

// Krok 1: Logowanie
echo "1. Logowanie użytkownika...\n";
$loginResponse = Http::post("$baseUrl/auth/login", [
    'email' => $email,
    'password' => $password,
]);

if (!$loginResponse->successful()) {
    echo "❌ Błąd logowania!\n";
    echo "Status: " . $loginResponse->status() . "\n";
    echo "Odpowiedź: " . $loginResponse->body() . "\n";
    exit(1);
}

$loginData = $loginResponse->json();
$token = $loginData['token'] ?? null;

if (!$token) {
    echo "❌ Nie znaleziono tokenu w odpowiedzi!\n";
    exit(1);
}

echo "✓ Zalogowano pomyślnie\n";
echo "Token: " . substr($token, 0, 50) . "...\n\n";

// Krok 2: Pobranie danych użytkownika
echo "2. Pobieranie danych użytkownika...\n";
$userResponse = Http::withToken($token)->get("$baseUrl/users/me");

if ($userResponse->successful()) {
    $userData = $userResponse->json()['data'] ?? $userResponse->json();
    echo "✓ Dane użytkownika:\n";
    echo "  Email: " . ($userData['email'] ?? 'N/A') . "\n";
    echo "  Imię: " . ($userData['first_name'] ?? 'N/A') . "\n";
    echo "  Nazwisko: " . ($userData['last_name'] ?? 'N/A') . "\n";
    echo "  Locale: " . ($userData['locale'] ?? 'N/A') . "\n\n";
} else {
    echo "⚠ Nie udało się pobrać danych użytkownika\n\n";
}

// Krok 3: Test 1 - Tworzenie attendee BEZ podawania danych
echo "3. Test 1: Tworzenie attendee BEZ podawania danych (automatyczne wypełnienie z konta)...\n";
$attendeeResponse1 = Http::withToken($token)->post("$baseUrl/events/$eventId/attendees", [
    'product_id' => $productId,
    'product_price_id' => $productPriceId,
    'amount_paid' => 0.00,
    'send_confirmation_email' => false,
    'taxes_and_fees' => [],
]);

if ($attendeeResponse1->status() === 201) {
    echo "✓ Attendee utworzony pomyślnie!\n";
    $attendeeData1 = $attendeeResponse1->json()['data'] ?? $attendeeResponse1->json();
    echo "  ID: " . ($attendeeData1['id'] ?? 'N/A') . "\n";
    echo "  Email: " . ($attendeeData1['email'] ?? 'N/A') . "\n";
    echo "  Imię: " . ($attendeeData1['first_name'] ?? 'N/A') . "\n";
    echo "  Nazwisko: " . ($attendeeData1['last_name'] ?? 'N/A') . "\n";
} else {
    echo "❌ Błąd tworzenia attendee (HTTP " . $attendeeResponse1->status() . ")\n";
    echo "Odpowiedź: " . $attendeeResponse1->body() . "\n";
}
echo "\n";

// Krok 4: Test 2 - Tworzenie attendee Z podaniem danych
echo "4. Test 2: Tworzenie attendee Z podaniem danych (nadpisanie danych z konta)...\n";
$attendeeResponse2 = Http::withToken($token)->post("$baseUrl/events/$eventId/attendees", [
    'product_id' => $productId,
    'product_price_id' => $productPriceId,
    'email' => 'custom.email@example.com',
    'first_name' => 'Custom',
    'last_name' => 'Name',
    'locale' => 'pl',
    'amount_paid' => 0.00,
    'send_confirmation_email' => false,
    'taxes_and_fees' => [],
]);

if ($attendeeResponse2->status() === 201) {
    echo "✓ Attendee utworzony pomyślnie z własnymi danymi!\n";
    $attendeeData2 = $attendeeResponse2->json()['data'] ?? $attendeeResponse2->json();
    echo "  ID: " . ($attendeeData2['id'] ?? 'N/A') . "\n";
    echo "  Email: " . ($attendeeData2['email'] ?? 'N/A') . "\n";
    echo "  Imię: " . ($attendeeData2['first_name'] ?? 'N/A') . "\n";
    echo "  Nazwisko: " . ($attendeeData2['last_name'] ?? 'N/A') . "\n";
} else {
    echo "❌ Błąd tworzenia attendee (HTTP " . $attendeeResponse2->status() . ")\n";
    echo "Odpowiedź: " . $attendeeResponse2->body() . "\n";
}
echo "\n";

// Krok 5: Test 3 - Próba utworzenia attendee BEZ autoryzacji
echo "5. Test 3: Próba utworzenia attendee BEZ autoryzacji (powinno wymagać wszystkich danych)...\n";
$attendeeResponse3 = Http::post("$baseUrl/events/$eventId/attendees", [
    'product_id' => $productId,
    'product_price_id' => $productPriceId,
    'amount_paid' => 0.00,
    'send_confirmation_email' => false,
    'taxes_and_fees' => [],
]);

if (in_array($attendeeResponse3->status(), [401, 422])) {
    echo "✓ Poprawnie wymaga autoryzacji lub wszystkich danych (HTTP " . $attendeeResponse3->status() . ")\n";
} else {
    echo "⚠ Nieoczekiwany kod odpowiedzi: " . $attendeeResponse3->status() . "\n";
}
echo "Odpowiedź: " . $attendeeResponse3->body() . "\n\n";

echo "=== Testy zakończone ===\n";

