# Endpoint: Moje wydarzenia

## Opis

Endpoint zwraca wszystkie wydarzenia, na które zalogowany użytkownik jest zapisany (jako attendee).

## Endpoint

```
GET /api/users/me/events
```

## Autoryzacja

Wymagana - endpoint wymaga tokenu JWT w headerze:
```
Authorization: Bearer YOUR_TOKEN
```

## Parametry query (opcjonalne)

- `page` - Numer strony (domyślnie: 1)
- `per_page` - Liczba wyników na stronę (domyślnie: 15)
- `query` - Wyszukiwanie po tytule wydarzenia
- `sort_by` - Sortowanie (domyślnie: `created_at`)
- `sort_direction` - Kierunek sortowania: `asc` lub `desc` (domyślnie: `desc`)

## Przykład użycia

### cURL

```bash
curl -X GET "http://localhost:8000/api/users/me/events" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

### Z parametrami

```bash
curl -X GET "http://localhost:8000/api/users/me/events?page=1&per_page=10&query=konferencja" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

## Odpowiedź

### Sukces (200 OK)

```json
{
  "data": [
    {
      "id": 1,
      "title": "Test Event",
      "description": "Opis wydarzenia",
      "start_date": "2025-12-09T21:00:00.000000Z",
      "end_date": "2025-12-10T21:00:00.000000Z",
      "status": "LIVE",
      "organizer": {
        "id": 1,
        "name": "Test Organizer"
      },
      ...
    }
  ],
  "links": {
    "first": "http://localhost:8000/api/users/me/events?page=1",
    "last": "http://localhost:8000/api/users/me/events?page=1",
    "prev": null,
    "next": null
  },
  "meta": {
    "current_page": 1,
    "from": 1,
    "last_page": 1,
    "path": "http://localhost:8000/api/users/me/events",
    "per_page": 15,
    "to": 1,
    "total": 1
  }
}
```

## Uwagi

- Endpoint zwraca tylko wydarzenia, na które użytkownik jest zapisany jako attendee (gdzie `attendees.user_id` = ID zalogowanego użytkownika)
- Jeśli użytkownik ma wiele attendees dla tego samego wydarzenia, wydarzenie pojawi się tylko raz (używamy `distinct()`)
- Endpoint uwzględnia tylko nieusunięte attendees (`deleted_at IS NULL`)
- Zwracane są wszystkie wydarzenia, niezależnie od ich statusu (DRAFT, LIVE, ARCHIVED)

## Implementacja

- **Repository**: `EventRepository::findEventsForUser()`
- **Handler**: `GetUserEventsHandler`
- **Action**: `GetMyEventsAction`
- **Route**: `/api/users/me/events` (wymaga `auth:api` middleware)

