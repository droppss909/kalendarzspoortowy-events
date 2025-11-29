#!/bin/bash

# Skrypt do testowania API zapisywania się na eventy
# Użycie: ./test_attendee_api.sh [BASE_URL] [EMAIL] [PASSWORD] [EVENT_ID] [PRODUCT_ID] [PRODUCT_PRICE_ID]

# Kolory dla lepszej czytelności
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parametry
BASE_URL="${1:-http://localhost:8000/api}"
EMAIL="${2:-test@example.com}"
PASSWORD="${3:-password}"
EVENT_ID="${4:-1}"
PRODUCT_ID="${5:-1}"
PRODUCT_PRICE_ID="${6:-1}"

echo -e "${YELLOW}=== Test API zapisywania się na eventy ===${NC}"
echo "Base URL: $BASE_URL"
echo "Email: $EMAIL"
echo "Event ID: $EVENT_ID"
echo "Product ID: $PRODUCT_ID"
echo "Product Price ID: $PRODUCT_PRICE_ID"
echo ""

# Krok 1: Logowanie
echo -e "${YELLOW}1. Logowanie użytkownika...${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

# Sprawdź czy logowanie się powiodło
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | grep -o '[^"]*$')
X_AUTH_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | grep -o '[^"]*$')

if [ -z "$TOKEN" ]; then
  echo -e "${RED}❌ Błąd logowania!${NC}"
  echo "Odpowiedź: $LOGIN_RESPONSE"
  exit 1
fi

echo -e "${GREEN}✓ Zalogowano pomyślnie${NC}"
echo "Token: ${TOKEN:0:50}..."
echo ""

# Krok 2: Pobranie danych użytkownika (opcjonalne, do weryfikacji)
echo -e "${YELLOW}2. Pobieranie danych użytkownika...${NC}"
USER_RESPONSE=$(curl -s -X GET "$BASE_URL/users/me" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json")

USER_EMAIL=$(echo $USER_RESPONSE | grep -o '"email":"[^"]*' | grep -o '[^"]*$')
USER_FIRST_NAME=$(echo $USER_RESPONSE | grep -o '"first_name":"[^"]*' | grep -o '[^"]*$')
USER_LAST_NAME=$(echo $USER_RESPONSE | grep -o '"last_name":"[^"]*' | grep -o '[^"]*$')
USER_LOCALE=$(echo $USER_RESPONSE | grep -o '"locale":"[^"]*' | grep -o '[^"]*$')

echo -e "${GREEN}✓ Dane użytkownika:${NC}"
echo "  Email: $USER_EMAIL"
echo "  Imię: $USER_FIRST_NAME"
echo "  Nazwisko: $USER_LAST_NAME"
echo "  Locale: $USER_LOCALE"
echo ""

# Krok 3: Test 1 - Tworzenie attendee BEZ podawania danych (powinno użyć danych z konta)
echo -e "${YELLOW}3. Test 1: Tworzenie attendee BEZ podawania danych (automatyczne wypełnienie z konta)...${NC}"
ATTENDEE_RESPONSE_1=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/events/$EVENT_ID/attendees" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"product_id\": $PRODUCT_ID,
    \"product_price_id\": $PRODUCT_PRICE_ID,
    \"amount_paid\": 0.00,
    \"send_confirmation_email\": false,
    \"taxes_and_fees\": []
  }")

HTTP_CODE_1=$(echo "$ATTENDEE_RESPONSE_1" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
ATTENDEE_BODY_1=$(echo "$ATTENDEE_RESPONSE_1" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HTTP_CODE_1" = "201" ]; then
  echo -e "${GREEN}✓ Attendee utworzony pomyślnie!${NC}"
  echo "Odpowiedź: $ATTENDEE_BODY_1" | head -20
else
  echo -e "${RED}❌ Błąd tworzenia attendee (HTTP $HTTP_CODE_1)${NC}"
  echo "Odpowiedź: $ATTENDEE_BODY_1"
fi
echo ""

# Krok 4: Test 2 - Tworzenie attendee Z podaniem danych (powinno użyć podanych danych)
echo -e "${YELLOW}4. Test 2: Tworzenie attendee Z podaniem danych (nadpisanie danych z konta)...${NC}"
ATTENDEE_RESPONSE_2=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/events/$EVENT_ID/attendees" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"product_id\": $PRODUCT_ID,
    \"product_price_id\": $PRODUCT_PRICE_ID,
    \"email\": \"custom.email@example.com\",
    \"first_name\": \"Custom\",
    \"last_name\": \"Name\",
    \"locale\": \"pl\",
    \"amount_paid\": 0.00,
    \"send_confirmation_email\": false,
    \"taxes_and_fees\": []
  }")

HTTP_CODE_2=$(echo "$ATTENDEE_RESPONSE_2" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
ATTENDEE_BODY_2=$(echo "$ATTENDEE_RESPONSE_2" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HTTP_CODE_2" = "201" ]; then
  echo -e "${GREEN}✓ Attendee utworzony pomyślnie z własnymi danymi!${NC}"
  echo "Odpowiedź: $ATTENDEE_BODY_2" | head -20
else
  echo -e "${RED}❌ Błąd tworzenia attendee (HTTP $HTTP_CODE_2)${NC}"
  echo "Odpowiedź: $ATTENDEE_BODY_2"
fi
echo ""

# Krok 5: Test 3 - Próba utworzenia attendee BEZ autoryzacji (powinno wymagać danych)
echo -e "${YELLOW}5. Test 3: Próba utworzenia attendee BEZ autoryzacji (powinno wymagać wszystkich danych)...${NC}"
ATTENDEE_RESPONSE_3=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/events/$EVENT_ID/attendees" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"product_id\": $PRODUCT_ID,
    \"product_price_id\": $PRODUCT_PRICE_ID,
    \"amount_paid\": 0.00,
    \"send_confirmation_email\": false,
    \"taxes_and_fees\": []
  }")

HTTP_CODE_3=$(echo "$ATTENDEE_RESPONSE_3" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
ATTENDEE_BODY_3=$(echo "$ATTENDEE_RESPONSE_3" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HTTP_CODE_3" = "401" ] || [ "$HTTP_CODE_3" = "422" ]; then
  echo -e "${GREEN}✓ Poprawnie wymaga autoryzacji lub wszystkich danych (HTTP $HTTP_CODE_3)${NC}"
else
  echo -e "${YELLOW}⚠ Nieoczekiwany kod odpowiedzi: $HTTP_CODE_3${NC}"
fi
echo "Odpowiedź: $ATTENDEE_BODY_3"
echo ""

echo -e "${GREEN}=== Testy zakończone ===${NC}"

