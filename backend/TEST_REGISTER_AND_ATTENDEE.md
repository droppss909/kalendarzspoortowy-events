# Test: Rejestracja użytkownika + zapis na event

## Opis

Skrypt `test_register_and_attendee.sh` automatycznie:
1. Rejestruje nowego użytkownika
2. Loguje go (token z rejestracji)
3. Tworzy organizatora (lub używa istniejącego)
4. Tworzy event
5. Tworzy produkt (bilet) z ceną
6. **Testuje zapisanie użytkownika na event BEZ podawania danych** - dane są automatycznie wypełniane z konta użytkownika

## Użycie

```bash
cd backend
./test_register_and_attendee.sh [BASE_URL]
```

### Przykład:

```bash
# Domyślny URL (http://localhost:8000/api)
./test_register_and_attendee.sh

# Z własnym URL
./test_register_and_attendee.sh http://localhost:8000/api
```

## Co robi skrypt

1. **Rejestracja użytkownika**
   - Generuje losowy email (test_TIMESTAMP@example.com)
   - Tworzy konto z danymi: Jan Kowalski, timezone: Europe/Warsaw, currency: PLN

2. **Pobranie tokenu**
   - Wyciąga token JWT z odpowiedzi rejestracji
   - Token jest używany do wszystkich kolejnych zapytań

3. **Utworzenie organizatora**
   - Tworzy nowego organizatora lub używa istniejącego

4. **Utworzenie eventu**
   - Tworzy event z datami: start za 1 dzień, koniec za 2 dni
   - Status: PUBLISHED

5. **Utworzenie produktu**
   - Tworzy bilet "Bilet testowy"
   - Cena: 0.00 PLN (darmowy)
   - Dostępność: 100 sztuk

6. **Test zapisu na event**
   - **Kluczowy test**: Zapisuje użytkownika na event **BEZ podawania email, first_name, last_name, locale**
   - System automatycznie wypełnia te dane z konta użytkownika
   - Weryfikuje czy dane attendee zgadzają się z danymi użytkownika

## Oczekiwany wynik

```
✓✓✓ SUKCES! Użytkownik zapisany na event bez podawania danych!
✓✓✓ WERYFIKACJA: Dane attendee zgadzają się z danymi użytkownika!
```

## Wymagania

- `curl` - do wykonywania zapytań HTTP
- `jq` (opcjonalnie) - do lepszego parsowania JSON (jeśli dostępne, skrypt użyje go automatycznie)
- Działający backend Laravel na podanym URL
- Włączona rejestracja użytkowników (`app.disable_registration = false`)

## Rozwiązywanie problemów

### Błąd rejestracji (HTTP 403)
- Sprawdź czy rejestracja jest włączona: `config('app.disable_registration')` powinno być `false`

### Błąd tworzenia organizatora
- Skrypt automatycznie spróbuje użyć istniejącego organizatora
- Jeśli nie ma żadnego organizatora, musisz go utworzyć ręcznie

### Błąd parsowania JSON
- Zainstaluj `jq` dla lepszego parsowania: `sudo apt-get install jq` (Ubuntu/Debian) lub `brew install jq` (macOS)

### Błąd zapisu na event
- Sprawdź czy event został utworzony poprawnie
- Sprawdź czy produkt ma cenę (product_price_id)
- Sprawdź czy są dostępne bilety (initial_quantity_available > 0)

## Przykładowy output

```
=== Test: Rejestracja użytkownika + zapis na event ===
Base URL: http://localhost:8000/api

1. Rejestracja nowego użytkownika...
✓ Użytkownik zarejestrowany pomyślnie!
Email: test_1234567890@example.com
Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

2. Pobieranie danych użytkownika...
✓ Dane użytkownika:
  Email: test_1234567890@example.com
  Imię: Jan
  Nazwisko: Kowalski

3. Tworzenie organizatora...
✓ Organizator utworzony pomyślnie! (ID: 1)

4. Tworzenie eventu...
✓ Event utworzony pomyślnie! (ID: 1)

5. Tworzenie produktu (biletu)...
✓ Produkt utworzony pomyślnie!
  Product ID: 1
  Product Price ID: 1

6. Test: Zapisanie użytkownika na event BEZ podawania danych...
✓✓✓ SUKCES! Użytkownik zapisany na event bez podawania danych!

Dane attendee (wypełnione automatycznie z konta):
  Email: test_1234567890@example.com
  Imię: Jan
  Nazwisko: Kowalski

✓✓✓ WERYFIKACJA: Dane attendee zgadzają się z danymi użytkownika!

=== Podsumowanie ===
✓ Użytkownik zarejestrowany: test_1234567890@example.com
✓ Event utworzony: ID 1
✓ Produkt utworzony: ID 1
✓ Użytkownik zapisany na event bez podawania danych

=== Test zakończony pomyślnie! ===
```


