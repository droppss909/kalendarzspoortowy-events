# Kategorie wiekowe z płcią

## Format reguły
- Endpoint: `POST /events/{event_id}/products/{ticket_id}/age-category-rule`
- Walidacja (`AssignTicketAgeRuleRequest`): każdy bin wymaga `min`, `max`, `age_category`; opcjonalne `gender` (`M` lub `F`).
- Przykładowy payload:
  ```json
  {
    "name": "Gendered Rule",
    "calc_mode": "BY_AGE",
    "rule": {
      "bins": [
        {"min": 18, "max": 29, "gender": "M", "age_category": "M20"},
        {"min": 18, "max": 29, "gender": "F", "age_category": "F20"},
        {"min": 30, "max": 39, "gender": "M", "age_category": "M30"},
        {"min": 30, "max": 39, "gender": "F", "age_category": "F30"},
        {"min": 40, "max": 120, "gender": "M", "age_category": "M40"},
        {"min": 40, "max": 120, "gender": "F", "age_category": "F40"}
      ]
    },
    "version": 1,
    "is_active": true
  }
  ```

## Tworzenie uczestnika (wyznaczanie kategorii)
- Żądania walidowane przez `CreateAttendeeRequest`; dla gości `birth_date` i `gender` są wymagane, dla zalogowanych są auto-uzupełniane z profilu, jeśli pominięte.
- DTO: `CreateAttendeeDTO` przenosi `birth_date`, `gender` i opcjonalnie `age_category`.
- Handler: `CreateAttendeeHandler::resolveAgeCategoryFromTicket(productId, birthDate, gender)`:
  - Ładuje aktywną regułę dla biletu z `ticket_age_rule_assignment` i `age_category_rules`.
  - Iteruje po binach; dopasowuje zakres wieku i ewentualnie płeć.
  - Zwraca `age_category`; jeśli etykieta nie zaczyna się od `M`/`F`, a znamy płeć, prefiksuje ją.
- Zapisywane w `attendees.age_category` (schemat bez zmian); brak osobnej kolumny płci dla uczestników.

## Endpointy (publiczny vs. zalogowany)
- Zalogowany: `POST /events/{event_id}/attendees` (używa danych użytkownika konta, jeśli dostępne).
- Publiczny (bez auth): `POST /public/events/{event_id}/attendees` (`CreateAttendeePublicAction`) dla gości; trzeba podać `birth_date`, `gender` i dane biletu.

## Przechowywanie płci użytkownika
- Migracja: `backend/database/migrations/2025_12_16_000002_add_gender_to_users.php` dodaje `gender` (string, max 20) do `users`.
- Przepływy użytkownika:
  - Rejestracja (`CreateAccountAction`, `CreateAccountRequest`) wymaga `gender`.
  - Aktualizacja profilu (`UpdateMeAction`/`UpdateMeRequest`) pozwala zmienić `gender`.
  - `UserResource` wystawia `gender`.
  - Płeć zalogowanego użytkownika jest wstrzykiwana do tworzenia uczestnika.

## Test dymny
- Skrypt `backend/scripts/api_age_rule_gender.sh` rejestruje użytkowników, tworzy wydarzenia/bilety, przypisuje reguły z płcią i tworzy uczestników (auth + public), weryfikując `age_category`.
