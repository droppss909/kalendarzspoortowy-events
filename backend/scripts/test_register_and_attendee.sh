#!/bin/bash

# Skrypt do testowania: rejestracja użytkownika + zapis na event
# Użycie: ./test_register_and_attendee.sh [BASE_URL]

# Kolory dla lepszej czytelności
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parametry
# Jeśli BASE_URL nie zawiera /api, dodajemy go automatycznie
BASE_URL="${1:-http://localhost:8000}"

# Informacja o konfiguracji dla testów
echo -e "${YELLOW}ℹ Dla testów zalecane ustawienia w pliku .env:${NC}"
echo -e "${YELLOW}   MAIL_MAILER=log${NC}"
echo -e "${YELLOW}   FILESYSTEM_PUBLIC_DISK=public${NC}"
echo -e "${YELLOW}   FILESYSTEM_PRIVATE_DISK=local${NC}"
echo ""


# Generuj losowe dane użytkownika
TIMESTAMP=$(date +%s)
RANDOM_EMAIL="test_${TIMESTAMP}@example.com"
RANDOM_PASSWORD="TestPassword123!"
FIRST_NAME="Jan"
LAST_NAME="Kowalski"
TIMEZONE="Europe/Warsaw"
CURRENCY_CODE="PLN"
# Używamy 'en' bo 'pl' nie jest obsługiwane w systemie
# Obsługiwane locale: en, de, fr, it, nl, hu, es, pt, pt-br, zh-cn, zh-hk, vi, tr
LOCALE="en"

echo -e "${BLUE}=== Test: Rejestracja użytkownika + zapis na event ===${NC}"
echo "Base URL: $BASE_URL"
echo ""

# Funkcja pomocnicza do wyciągania wartości z JSON
extract_json_value() {
    # Spróbuj najpierw z "data" wrapperem
    VALUE=$(echo "$1" | grep -o "\"data\":{[^}]*\"$2\":\"[^\"]*" | grep -o "\"$2\":\"[^\"]*" | grep -o '[^"]*$')
    if [ -z "$VALUE" ]; then
        # Jeśli nie ma "data", spróbuj bezpośrednio
        VALUE=$(echo "$1" | grep -o "\"$2\":\"[^\"]*" | grep -o '[^"]*$' | head -1)
    fi
    echo "$VALUE"
}

extract_json_number() {
    # Spróbuj najpierw z "data" wrapperem
    VALUE=$(echo "$1" | grep -o "\"data\":{[^}]*\"$2\":[0-9]*" | grep -o "\"$2\":[0-9]*" | grep -o '[0-9]*$')
    if [ -z "$VALUE" ]; then
        # Jeśli nie ma "data", spróbuj bezpośrednio
        VALUE=$(echo "$1" | grep -o "\"$2\":[0-9]*" | grep -o '[0-9]*$' | head -1)
    fi
    echo "$VALUE"
}

# Funkcja pomocnicza: tworzy użytkownika, organizatora, event, produkt i zapisuje użytkownika na jego własny event
create_user_with_event_and_attendance() {
  local INDEX="$1"
  local EMAIL="prep_${TIMESTAMP}_${INDEX}@example.com"
  local PASSWORD="$RANDOM_PASSWORD"
  local FIRST="Prep${INDEX}"
  local LAST="User${INDEX}"

  echo -e "${YELLOW}➕ Tworzenie użytkownika testowego #${INDEX} (${EMAIL})...${NC}"
  local REGISTER_RESPONSE
  REGISTER_RESPONSE=$(curl -s -i -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "{
      \"first_name\": \"$FIRST\",
      \"last_name\": \"$LAST\",
      \"email\": \"$EMAIL\",
      \"password\": \"$PASSWORD\",
      \"password_confirmation\": \"$PASSWORD\",
      \"timezone\": \"$TIMEZONE\",
      \"currency_code\": \"$CURRENCY_CODE\",
      \"locale\": \"$LOCALE\"
    }")

  local HTTP_CODE
  HTTP_CODE=$(echo "$REGISTER_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
  local REGISTER_FULL
  REGISTER_FULL=$(echo "$REGISTER_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')
  local TOKEN
  TOKEN=$(echo "$REGISTER_FULL" | grep -i "X-Auth-Token:" | cut -d' ' -f2 | tr -d '\r\n')
  local REGISTER_BODY
  REGISTER_BODY=$(echo "$REGISTER_FULL" | sed -n '/^$/,$p' | sed '1d')

  if [ "$HTTP_CODE" != "201" ]; then
    echo -e "${RED}❌ Nie udało się utworzyć użytkownika #${INDEX}! (HTTP $HTTP_CODE)${NC}"
    echo "Odpowiedź: $REGISTER_BODY"
    exit 1
  fi

  if [ -z "$TOKEN" ]; then
    if command -v jq &> /dev/null; then
      TOKEN=$(echo "$REGISTER_BODY" | jq -r '.token // .data.token // empty')
    fi
  fi
  if [ -z "$TOKEN" ]; then
    TOKEN=$(extract_json_value "$REGISTER_BODY" "token")
  fi

  if [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ Nie udało się uzyskać tokenu dla użytkownika #${INDEX}!${NC}"
    exit 1
  fi

  local ORGANIZER_RESPONSE
  ORGANIZER_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/organizers" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "{
      \"name\": \"Prep Organizer ${INDEX}\",
      \"email\": \"organizer_${INDEX}@example.com\",
      \"timezone\": \"$TIMEZONE\",
      \"currency\": \"$CURRENCY_CODE\"
    }")
  local HTTP_CODE_ORG
  HTTP_CODE_ORG=$(echo "$ORGANIZER_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
  local ORGANIZER_BODY
  ORGANIZER_BODY=$(echo "$ORGANIZER_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')
  local ORGANIZER_ID
  ORGANIZER_ID=$(extract_json_number "$ORGANIZER_BODY" "id")

  if [ "$HTTP_CODE_ORG" != "201" ] && [ "$HTTP_CODE_ORG" != "200" ]; then
    echo -e "${RED}❌ Nie udało się utworzyć organizatora dla użytkownika #${INDEX}!${NC}"
    echo "Odpowiedź: $ORGANIZER_BODY"
    exit 1
  fi

  local START_DATE
  START_DATE=$(date -u -d "+1 day" +"%Y-%m-%dT%H:00:00Z" 2>/dev/null || date -u -v+1d +"%Y-%m-%dT%H:00:00Z" 2>/dev/null || date -u +"%Y-%m-%dT%H:00:00Z")
  local END_DATE
  END_DATE=$(date -u -d "+2 days" +"%Y-%m-%dT%H:00:00Z" 2>/dev/null || date -u -v+2d +"%Y-%m-%dT%H:00:00Z" 2>/dev/null || date -u +"%Y-%m-%dT%H:00:00Z")

  local EVENT_RESPONSE
  EVENT_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/events" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "{
      \"title\": \"Prep Event ${INDEX} $(date +%s)\",
      \"description\": \"Event utworzony automatycznie do testów zbiorczych\",
      \"start_date\": \"$START_DATE\",
      \"end_date\": \"$END_DATE\",
      \"timezone\": \"$TIMEZONE\",
      \"currency\": \"$CURRENCY_CODE\",
      \"organizer_id\": $ORGANIZER_ID,
      \"status\": \"PUBLISHED\"
    }")

  local HTTP_CODE_EVENT
  HTTP_CODE_EVENT=$(echo "$EVENT_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
  local EVENT_BODY
  EVENT_BODY=$(echo "$EVENT_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')
  local EVENT_ID
  EVENT_ID=$(extract_json_number "$EVENT_BODY" "id")

  if [ "$HTTP_CODE_EVENT" != "201" ] && [ "$HTTP_CODE_EVENT" != "200" ]; then
    echo -e "${RED}❌ Nie udało się utworzyć eventu dla użytkownika #${INDEX}! (HTTP $HTTP_CODE_EVENT)${NC}"
    echo "Odpowiedź: $EVENT_BODY"
    exit 1
  fi

  local CATEGORY_RESPONSE
  CATEGORY_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/events/$EVENT_ID/product-categories" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "{
      \"name\": \"Prep Tickets ${INDEX}\",
      \"is_hidden\": false
    }")
  local HTTP_CODE_CAT
  HTTP_CODE_CAT=$(echo "$CATEGORY_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
  local CATEGORY_BODY
  CATEGORY_BODY=$(echo "$CATEGORY_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')
  local PRODUCT_CATEGORY_ID
  if command -v jq &> /dev/null; then
    PRODUCT_CATEGORY_ID=$(echo "$CATEGORY_BODY" | jq -r '.data.id // .id // empty')
  else
    PRODUCT_CATEGORY_ID=$(extract_json_number "$CATEGORY_BODY" "id")
  fi

  if [ "$HTTP_CODE_CAT" != "201" ] && [ "$HTTP_CODE_CAT" != "200" ] || [ -z "$PRODUCT_CATEGORY_ID" ]; then
    echo -e "${RED}❌ Nie udało się utworzyć kategorii produktów dla eventu #${EVENT_ID}!${NC}"
    exit 1
  fi

  local PRODUCT_RESPONSE
  PRODUCT_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/events/$EVENT_ID/products" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "{
      \"title\": \"Prep Bilet ${INDEX}\",
      \"description\": \"Automatyczny bilet testowy\",
      \"type\": \"FREE\",
      \"product_type\": \"TICKET\",
      \"product_category_id\": $PRODUCT_CATEGORY_ID,
      \"prices\": [
        {
          \"price\": 0.00,
          \"label\": \"Darmowy\",
          \"initial_quantity_available\": 5
        }
      ]
    }")
  local HTTP_CODE_PRODUCT
  HTTP_CODE_PRODUCT=$(echo "$PRODUCT_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
  local PRODUCT_BODY
  PRODUCT_BODY=$(echo "$PRODUCT_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')
  local PRODUCT_ID
  local PRODUCT_PRICE_ID

  if command -v jq &> /dev/null; then
    PRODUCT_ID=$(echo "$PRODUCT_BODY" | jq -r '.data.id // .id // empty')
    PRODUCT_PRICE_ID=$(echo "$PRODUCT_BODY" | jq -r '.data.prices[0].id // .prices[0].id // empty')
  else
    PRODUCT_ID=$(extract_json_number "$PRODUCT_BODY" "id")
    PRODUCT_PRICE_ID=$(echo "$PRODUCT_BODY" | grep -o "\"prices\":\[{[^}]*\"id\":[0-9]*" | grep -o "\"id\":[0-9]*" | grep -o '[0-9]*$' | head -1)
  fi

  if [ "$HTTP_CODE_PRODUCT" != "201" ] && [ "$HTTP_CODE_PRODUCT" != "200" ] || [ -z "$PRODUCT_ID" ] || [ -z "$PRODUCT_PRICE_ID" ]; then
    echo -e "${RED}❌ Nie udało się utworzyć produktu dla eventu #${EVENT_ID}!${NC}"
    exit 1
  fi

  local ATTENDEE_RESPONSE
  ATTENDEE_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/events/$EVENT_ID/attendees" \
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
  local HTTP_CODE_ATT
  HTTP_CODE_ATT=$(echo "$ATTENDEE_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)

  if [ "$HTTP_CODE_ATT" != "201" ]; then
    echo -e "${RED}❌ Nie udało się zapisać użytkownika #${INDEX} na jego event! (HTTP $HTTP_CODE_ATT)${NC}"
    echo "Odpowiedź: $ATTENDEE_RESPONSE"
    exit 1
  fi

  PREP_USER_EMAILS+=("$EMAIL")
  PREP_EVENT_IDS+=("$EVENT_ID")
  echo -e "${GREEN}✓ Użytkownik #${INDEX} utworzył event (ID: $EVENT_ID) i zapisał się jako attendee${NC}"
}

PREP_USER_EMAILS=()
PREP_EVENT_IDS=()

echo -e "${BLUE}=== Przygotowanie: dodatkowi użytkownicy i wydarzenia ===${NC}"
MULTI_USER_COUNT=3
for i in $(seq 1 $MULTI_USER_COUNT); do
  create_user_with_event_and_attendance "$i"
done
echo -e "${GREEN}✓ Przygotowano $MULTI_USER_COUNT dodatkowych użytkowników z własnymi wydarzeniami i zapisami${NC}"
echo ""

# Krok 1: Rejestracja użytkownika
echo -e "${YELLOW}1. Rejestracja nowego użytkownika...${NC}"
REGISTER_RESPONSE=$(curl -s -i -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"first_name\": \"$FIRST_NAME\",
    \"last_name\": \"$LAST_NAME\",
    \"email\": \"$RANDOM_EMAIL\",
    \"password\": \"$RANDOM_PASSWORD\",
    \"password_confirmation\": \"$RANDOM_PASSWORD\",
    \"timezone\": \"$TIMEZONE\",
    \"currency_code\": \"$CURRENCY_CODE\",
    \"locale\": \"$LOCALE\"
  }")

HTTP_CODE=$(echo "$REGISTER_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
REGISTER_FULL=$(echo "$REGISTER_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

# Wyciągnij token z headera X-Auth-Token
TOKEN=$(echo "$REGISTER_FULL" | grep -i "X-Auth-Token:" | cut -d' ' -f2 | tr -d '\r\n')

# Wyciągnij body (wszystko po pustej linii oddzielającej headery od body)
REGISTER_BODY=$(echo "$REGISTER_FULL" | sed -n '/^$/,$p' | sed '1d')

if [ "$HTTP_CODE" != "201" ]; then
  echo -e "${RED}❌ Błąd rejestracji! (HTTP $HTTP_CODE)${NC}"
  echo "Odpowiedź: $REGISTER_BODY"
  exit 1
fi

# Jeśli nie ma tokenu w headerze, spróbuj z body JSON
if [ -z "$TOKEN" ]; then
  if command -v jq &> /dev/null; then
    TOKEN=$(echo "$REGISTER_BODY" | jq -r '.token // .data.token // empty')
  else
    TOKEN=$(extract_json_value "$REGISTER_BODY" "token")
  fi
fi

# Jeśli nadal nie ma tokenu, zaloguj użytkownika osobno
if [ -z "$TOKEN" ]; then
  echo -e "${YELLOW}⚠ Token nie znaleziony w odpowiedzi rejestracji, logowanie użytkownika...${NC}"
  LOGIN_RESPONSE=$(curl -s -i -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "{
      \"email\": \"$RANDOM_EMAIL\",
      \"password\": \"$RANDOM_PASSWORD\"
    }")
  
  TOKEN=$(echo "$LOGIN_RESPONSE" | grep -i "X-Auth-Token:" | cut -d' ' -f2 | tr -d '\r\n')
  
  if [ -z "$TOKEN" ]; then
    if command -v jq &> /dev/null; then
      LOGIN_BODY=$(echo "$LOGIN_RESPONSE" | sed -n '/^$/,$p' | sed '1d')
      TOKEN=$(echo "$LOGIN_BODY" | jq -r '.token // .data.token // empty')
    fi
  fi
fi

if [ -z "$TOKEN" ]; then
  echo -e "${RED}❌ Nie udało się uzyskać tokenu!${NC}"
  echo "Odpowiedź rejestracji: $REGISTER_BODY"
  exit 1
fi

echo -e "${GREEN}✓ Użytkownik zarejestrowany pomyślnie!${NC}"
echo "Email: $RANDOM_EMAIL"
echo "Token: ${TOKEN:0:50}..."
echo ""

# Krok 2: Pobranie danych użytkownika
echo -e "${YELLOW}2. Pobieranie danych użytkownika...${NC}"
USER_RESPONSE=$(curl -s -X GET "$BASE_URL/users/me" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json")

USER_EMAIL=$(extract_json_value "$USER_RESPONSE" "email")
USER_FIRST_NAME=$(extract_json_value "$USER_RESPONSE" "first_name")
USER_LAST_NAME=$(extract_json_value "$USER_RESPONSE" "last_name")

echo -e "${GREEN}✓ Dane użytkownika:${NC}"
echo "  Email: $USER_EMAIL"
echo "  Imię: $USER_FIRST_NAME"
echo "  Nazwisko: $USER_LAST_NAME"
echo ""

# Krok 3: Pobranie account_id (potrzebne do tworzenia eventu)
# Account ID jest zwykle w odpowiedzi rejestracji lub można go pobrać z /users/me
ACCOUNT_ID=$(extract_json_number "$REGISTER_BODY" "id")

# Jeśli nie ma w odpowiedzi rejestracji, spróbuj z /users/me
if [ -z "$ACCOUNT_ID" ]; then
  USER_DATA=$(curl -s -X GET "$BASE_URL/users/me" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/json")
  # Account ID może być w current_account_user
  if command -v jq &> /dev/null; then
    ACCOUNT_ID=$(echo "$USER_DATA" | jq -r '.data.current_account_user.account_id // .current_account_user.account_id // empty')
  fi
fi

if [ -z "$ACCOUNT_ID" ]; then
  echo -e "${YELLOW}⚠ Nie udało się automatycznie pobrać account_id, ale kontynuujemy...${NC}"
fi

if [ -n "$ACCOUNT_ID" ]; then
  echo "Account ID: $ACCOUNT_ID"
fi
echo ""

# Krok 4: Utworzenie organizatora
echo -e "${YELLOW}4. Tworzenie organizatora...${NC}"
ORGANIZER_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/organizers" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"name\": \"Test Organizer\",
    \"email\": \"organizer@example.com\",
    \"timezone\": \"$TIMEZONE\",
    \"currency\": \"$CURRENCY_CODE\"
  }")

HTTP_CODE_ORG=$(echo "$ORGANIZER_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
ORGANIZER_BODY=$(echo "$ORGANIZER_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')
ORGANIZER_ID=$(extract_json_number "$ORGANIZER_BODY" "id")

if [ "$HTTP_CODE_ORG" != "201" ] && [ "$HTTP_CODE_ORG" != "200" ]; then
  echo -e "${YELLOW}⚠ Nie udało się utworzyć organizatora (HTTP $HTTP_CODE_ORG)${NC}"
  echo "Odpowiedź: $ORGANIZER_BODY"
  echo -e "${YELLOW}Pobieranie istniejących organizatorów...${NC}"
  ORGANIZERS_RESPONSE=$(curl -s -X GET "$BASE_URL/organizers" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/json")
  ORGANIZER_ID=$(extract_json_number "$ORGANIZERS_RESPONSE" "id" | head -1)
  if [ -z "$ORGANIZER_ID" ]; then
    echo -e "${RED}❌ Nie znaleziono organizatora!${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ Używam istniejącego organizatora (ID: $ORGANIZER_ID)${NC}"
else
  echo -e "${GREEN}✓ Organizator utworzony pomyślnie! (ID: $ORGANIZER_ID)${NC}"
fi
echo ""

# Krok 5: Utworzenie eventu
echo -e "${YELLOW}5. Tworzenie eventu...${NC}"
START_DATE=$(date -u -d "+1 day" +"%Y-%m-%dT%H:00:00Z" 2>/dev/null || date -u -v+1d +"%Y-%m-%dT%H:00:00Z" 2>/dev/null || date -u +"%Y-%m-%dT%H:00:00Z")
END_DATE=$(date -u -d "+2 days" +"%Y-%m-%dT%H:00:00Z" 2>/dev/null || date -u -v+2d +"%Y-%m-%dT%H:00:00Z" 2>/dev/null || date -u +"%Y-%m-%dT%H:00:00Z")

EVENT_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/events" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"title\": \"Test Event $(date +%s)\",
    \"description\": \"Event utworzony automatycznie do testów\",
    \"start_date\": \"$START_DATE\",
    \"end_date\": \"$END_DATE\",
    \"timezone\": \"$TIMEZONE\",
    \"currency\": \"$CURRENCY_CODE\",
    \"organizer_id\": $ORGANIZER_ID,
    \"status\": \"PUBLISHED\"
  }")

HTTP_CODE_EVENT=$(echo "$EVENT_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
EVENT_BODY=$(echo "$EVENT_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')
EVENT_ID=$(extract_json_number "$EVENT_BODY" "id")

if [ "$HTTP_CODE_EVENT" != "201" ] && [ "$HTTP_CODE_EVENT" != "200" ]; then
  echo -e "${RED}❌ Błąd tworzenia eventu! (HTTP $HTTP_CODE_EVENT)${NC}"
  echo "Odpowiedź: $EVENT_BODY"
  exit 1
fi

echo -e "${GREEN}✓ Event utworzony pomyślnie! (ID: $EVENT_ID)${NC}"
echo ""

# Krok 6: Pobranie kategorii produktów dla eventu
echo -e "${YELLOW}6. Pobieranie kategorii produktów...${NC}"
CATEGORIES_RESPONSE=$(curl -s -X GET "$BASE_URL/events/$EVENT_ID/product-categories" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json")

# Wyciągnij pierwszą kategorię produktów
if command -v jq &> /dev/null; then
  PRODUCT_CATEGORY_ID=$(echo "$CATEGORIES_RESPONSE" | jq -r '.data[0].id // .[0].id // empty')
else
  PRODUCT_CATEGORY_ID=$(extract_json_number "$CATEGORIES_RESPONSE" "id" | head -1)
fi

if [ -z "$PRODUCT_CATEGORY_ID" ]; then
  echo -e "${YELLOW}⚠ Nie znaleziono kategorii produktów, próbuję utworzyć domyślną...${NC}"
  # Utwórz domyślną kategorię
  CREATE_CATEGORY_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/events/$EVENT_ID/product-categories" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "{
      \"name\": \"Tickets\",
      \"is_hidden\": false
    }")
  
  HTTP_CODE_CAT=$(echo "$CREATE_CATEGORY_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
  CATEGORY_BODY=$(echo "$CREATE_CATEGORY_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')
  
  if [ "$HTTP_CODE_CAT" = "201" ] || [ "$HTTP_CODE_CAT" = "200" ]; then
    if command -v jq &> /dev/null; then
      PRODUCT_CATEGORY_ID=$(echo "$CATEGORY_BODY" | jq -r '.data.id // .id // empty')
    else
      PRODUCT_CATEGORY_ID=$(extract_json_number "$CATEGORY_BODY" "id")
    fi
    echo -e "${GREEN}✓ Utworzono kategorię produktów (ID: $PRODUCT_CATEGORY_ID)${NC}"
  else
    echo -e "${RED}❌ Nie udało się utworzyć kategorii produktów!${NC}"
    exit 1
  fi
else
  echo -e "${GREEN}✓ Znaleziono kategorię produktów (ID: $PRODUCT_CATEGORY_ID)${NC}"
fi
echo ""

# Krok 7: Utworzenie produktu (biletu)
echo -e "${YELLOW}7. Tworzenie produktu (biletu)...${NC}"
PRODUCT_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/events/$EVENT_ID/products" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"title\": \"Bilet testowy\",
    \"description\": \"Bilet do testów\",
    \"type\": \"FREE\",
    \"product_type\": \"TICKET\",
    \"product_category_id\": $PRODUCT_CATEGORY_ID,
    \"prices\": [
      {
        \"price\": 0.00,
        \"label\": \"Darmowy\",
        \"initial_quantity_available\": 100
      }
    ]
  }")

HTTP_CODE_PRODUCT=$(echo "$PRODUCT_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
PRODUCT_BODY=$(echo "$PRODUCT_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HTTP_CODE_PRODUCT" != "201" ] && [ "$HTTP_CODE_PRODUCT" != "200" ]; then
  echo -e "${RED}❌ Błąd tworzenia produktu! (HTTP $HTTP_CODE_PRODUCT)${NC}"
  echo "Odpowiedź: $PRODUCT_BODY"
  exit 1
fi

# Wyciągnij product_id
if command -v jq &> /dev/null; then
  PRODUCT_ID=$(echo "$PRODUCT_BODY" | jq -r '.data.id // .id // empty')
else
  PRODUCT_ID=$(extract_json_number "$PRODUCT_BODY" "id")
fi

# Wyciągnij product_price_id z prices
# Może być w strukturze: "prices": [{"id": 123, ...}]
if command -v jq &> /dev/null; then
  PRODUCT_PRICE_ID=$(echo "$PRODUCT_BODY" | jq -r '.data.prices[0].id // .prices[0].id // empty')
else
  # Fallback bez jq - szukaj w prices
  PRODUCT_PRICE_ID=$(echo "$PRODUCT_BODY" | grep -o "\"prices\":\[{[^}]*\"id\":[0-9]*" | grep -o "\"id\":[0-9]*" | grep -o '[0-9]*$' | head -1)
fi

# Jeśli nie znaleziono product_price_id, spróbuj pobrać produkt z pełnymi danymi
if [ -z "$PRODUCT_PRICE_ID" ] && [ -n "$PRODUCT_ID" ]; then
  echo -e "${YELLOW}⚠ Pobieranie pełnych danych produktu...${NC}"
  PRODUCT_GET_RESPONSE=$(curl -s -X GET "$BASE_URL/events/$EVENT_ID/products/$PRODUCT_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/json")
  if command -v jq &> /dev/null; then
    PRODUCT_PRICE_ID=$(echo "$PRODUCT_GET_RESPONSE" | jq -r '.data.prices[0].id // .prices[0].id // empty')
  else
    PRODUCT_PRICE_ID=$(echo "$PRODUCT_GET_RESPONSE" | grep -o "\"prices\":\[{[^}]*\"id\":[0-9]*" | grep -o "\"id\":[0-9]*" | grep -o '[0-9]*$' | head -1)
  fi
fi

# Sprawdź czy mamy wszystkie wymagane wartości
if [ -z "$PRODUCT_ID" ]; then
  echo -e "${RED}❌ Nie udało się wyciągnąć PRODUCT_ID!${NC}"
  echo "Odpowiedź: $PRODUCT_BODY"
  exit 1
fi

if [ -z "$PRODUCT_PRICE_ID" ]; then
  echo -e "${RED}❌ Nie udało się wyciągnąć PRODUCT_PRICE_ID!${NC}"
  echo "Odpowiedź: $PRODUCT_BODY"
  exit 1
fi

echo -e "${GREEN}✓ Produkt utworzony pomyślnie!${NC}"
echo "  Product ID: $PRODUCT_ID"
echo "  Product Price ID: $PRODUCT_PRICE_ID"
echo ""

# Krok 8: Test zapisania użytkownika na event BEZ podawania danych
echo -e "${YELLOW}8. Test: Zapisanie użytkownika na event BEZ podawania danych (automatyczne wypełnienie z konta)...${NC}"

# Sprawdź czy mamy wszystkie wymagane ID
if [ -z "$PRODUCT_ID" ] || [ -z "$PRODUCT_PRICE_ID" ]; then
  echo -e "${RED}❌ Brakuje PRODUCT_ID lub PRODUCT_PRICE_ID!${NC}"
  echo "  Product ID: $PRODUCT_ID"
  echo "  Product Price ID: $PRODUCT_PRICE_ID"
  exit 1
fi

ATTENDEE_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/events/$EVENT_ID/attendees" \
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

HTTP_CODE_ATTENDEE=$(echo "$ATTENDEE_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
ATTENDEE_BODY=$(echo "$ATTENDEE_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HTTP_CODE_ATTENDEE" = "201" ]; then
  echo -e "${GREEN}✓✓✓ SUKCES! Użytkownik zapisany na event bez podawania danych!${NC}"
  ATTENDEE_EMAIL=$(extract_json_value "$ATTENDEE_BODY" "email")
  ATTENDEE_FIRST_NAME=$(extract_json_value "$ATTENDEE_BODY" "first_name")
  ATTENDEE_LAST_NAME=$(extract_json_value "$ATTENDEE_BODY" "last_name")
  
  echo ""
  echo -e "${GREEN}Dane attendee (wypełnione automatycznie z konta):${NC}"
  echo "  Email: $ATTENDEE_EMAIL"
  echo "  Imię: $ATTENDEE_FIRST_NAME"
  echo "  Nazwisko: $ATTENDEE_LAST_NAME"
  echo ""
  
  # Weryfikacja czy dane się zgadzają
  if [ "$ATTENDEE_EMAIL" = "$USER_EMAIL" ] && [ "$ATTENDEE_FIRST_NAME" = "$USER_FIRST_NAME" ]; then
    echo -e "${GREEN}✓✓✓ WERYFIKACJA: Dane attendee zgadzają się z danymi użytkownika!${NC}"
  else
    echo -e "${YELLOW}⚠ Dane attendee różnią się od danych użytkownika${NC}"
  fi
else
  echo -e "${RED}❌ Błąd zapisywania na event! (HTTP $HTTP_CODE_ATTENDEE)${NC}"
  echo "Odpowiedź: $ATTENDEE_BODY"
  exit 1
fi

# Krok 9: Pobranie eventów użytkownika (na które jest zapisany)
echo -e "${YELLOW}9. Pobieranie eventów użytkownika (na które jest zapisany)...${NC}"
USER_EVENTS_RESPONSE=$(curl -s -X GET "$BASE_URL/users/me/events" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json")

echo $USER_EVENTS_RESPONSE

if command -v jq &> /dev/null; then
  USER_EVENT_IDS=$(echo "$USER_EVENTS_RESPONSE" | jq -r '((.data // .) | (if type=="array" then . else [] end)) | map(.id // .event_id // (.event.id // empty)) | .[]')
else
  USER_EVENT_IDS=$(echo "$USER_EVENTS_RESPONSE" | grep -o "\"id\":[0-9]*" | grep -o '[0-9]*')
fi

if echo "$USER_EVENT_IDS" | grep -qx "$EVENT_ID"; then
  echo -e "${GREEN}✓ Endpoint /users/me/events zwraca event, na który zapisany jest użytkownik (ID: $EVENT_ID)${NC}"
else
  echo -e "${RED}❌ Endpoint /users/me/events nie zwrócił eventu, na który zapisany jest użytkownik!${NC}"
  echo "Odpowiedź: $USER_EVENTS_RESPONSE"
  exit 1
fi

echo ""
echo -e "${BLUE}=== Podsumowanie ===${NC}"
echo -e "${GREEN}✓ Przygotowano $MULTI_USER_COUNT dodatkowych użytkowników z eventami i własnymi zapisami${NC}"
echo -e "${GREEN}✓ Użytkownik zarejestrowany: $RANDOM_EMAIL${NC}"
echo -e "${GREEN}✓ Event utworzony: ID $EVENT_ID${NC}"
echo -e "${GREEN}✓ Endpoint /users/me/events zwrócił event użytkownika zapisującego się${NC}"
echo -e "${GREEN}✓ Produkt utworzony: ID $PRODUCT_ID${NC}"
echo -e "${GREEN}✓ Użytkownik zapisany na event bez podawania danych${NC}"
echo ""
echo -e "${BLUE}=== Test zakończony pomyślnie! ===${NC}"
