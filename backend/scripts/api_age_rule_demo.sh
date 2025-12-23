#!/usr/bin/env bash
set -euo pipefail

# Simple smoke script that exercises the age-category rule flow via HTTP calls.
# Requirements: bash, curl, jq, running API with the same routes as laravel api.php.

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

API_BASE=${API_BASE:-http://localhost:8000}
EMAIL_SUFFIX=$((RANDOM % 100000))
EMAIL="age-rule-${EMAIL_SUFFIX}@example.com"
PASSWORD='Password123!'
START_DATE=$(date -u -d '+1 day' +"%Y-%m-%dT%H:%M:%SZ")
END_DATE=$(date -u -d '+2 day' +"%Y-%m-%dT%H:%M:%SZ")

COOKIES=$(mktemp)
HEADERS=$(mktemp)
trap 'rm -f "$COOKIES" "$HEADERS"' EXIT

log() { printf '\n== %s ==\n' "$*"; }

extract_token() {
  awk 'BEGIN{IGNORECASE=1} /^X-Auth-Token:/ {gsub("\r",""); print $2}' "$HEADERS"
}

log "Registering account (${EMAIL})"
register_body=$(jq -n \
  --arg first "Jane" \
  --arg last "Doe" \
  --arg email "$EMAIL" \
  --arg pwd "$PASSWORD" \
  '{
    first_name: $first,
    last_name: $last,
    email: $email,
    password: $pwd,
    password_confirmation: $pwd,
    timezone: "UTC",
    currency_code: "USD",
    locale: "en",
    birth_date: "1990-01-01",
    invite_token: null
  }')

register_response=$(curl -sS -f -D "$HEADERS" -b "$COOKIES" -c "$COOKIES" \
  -H 'Content-Type: application/json' \
  -X POST "$API_BASE/auth/register" \
  -d "$register_body")


echo $register_response
TOKEN=$(extract_token)
if [ -z "$TOKEN" ]; then
  echo "Failed to extract X-Auth-Token from register response headers" >&2
  exit 1
fi
AUTH_HEADER=("Authorization: Bearer $TOKEN")
echo "Got token: $TOKEN"

log "Creating organizer"
organizer_body=$(jq -n '{
  name: "Test Organizer",
  email: "organizer@example.com",
  timezone: "UTC",
  currency: "USD",
  description: "Demo organizer",
  phone: null,
  website: null
}')
organizer_response=$(curl -sS -f -b "$COOKIES" -H 'Content-Type: application/json' -H "${AUTH_HEADER[@]}" \
  -X POST "$API_BASE/organizers" -d "$organizer_body")
ORGANIZER_ID=$(echo "$organizer_response" | jq -r '.data.id')
echo "Organizer ID: $ORGANIZER_ID"

log "Creating event"
event_body=$(jq -n \
  --arg start "$START_DATE" \
  --arg end "$END_DATE" \
  --arg organizer_id "$ORGANIZER_ID" \
  '{
    title: "Age Rule Demo Event",
    description: "Demo event",
    start_date: $start,
    end_date: $end,
    organizer_id: ($organizer_id | tonumber),
    timezone: "UTC",
    currency: "USD",
    attributes: []
  }')
event_response=$(curl -sS -f -b "$COOKIES" -H 'Content-Type: application/json' -H "${AUTH_HEADER[@]}" \
  -X POST "$API_BASE/events" -d "$event_body")
EVENT_ID=$(echo "$event_response" | jq -r '.data.id')
PRODUCT_CATEGORY_ID=$(echo "$event_response" | jq -r '.data.product_categories[0].id // empty')
echo "Event ID: $EVENT_ID"

if [ -z "$PRODUCT_CATEGORY_ID" ]; then
  log "Fetching default product category"
  categories=$(curl -sS -f -b "$COOKIES" -H "${AUTH_HEADER[@]}" "$API_BASE/events/$EVENT_ID/product-categories")
  PRODUCT_CATEGORY_ID=$(echo "$categories" | jq -r '.data[0].id')
fi
echo "Product category ID: $PRODUCT_CATEGORY_ID"

log "Creating ticket/product"
product_body=$(jq -n \
  --argjson product_category_id "$PRODUCT_CATEGORY_ID" \
  '{
    title: "VIP Ticket",
    type: "PAID",
    product_type: "TICKET",
    product_category_id: $product_category_id,
    prices: [{
      price: 50.00,
      label: null,
      sale_start_date: null,
      sale_end_date: null,
      initial_quantity_available: 100,
      is_hidden: false
    }],
    order: 1,
    max_per_order: 1,
    min_per_order: 0,
    is_hidden: false,
    hide_before_sale_start_date: false,
    hide_after_sale_end_date: false,
    hide_when_sold_out: false,
    start_collapsed: false,
    show_quantity_remaining: true,
    is_hidden_without_promo_code: false
  }')
product_response=$(curl -sS -f -b "$COOKIES" -H 'Content-Type: application/json' -H "${AUTH_HEADER[@]}" \
  -X POST "$API_BASE/events/$EVENT_ID/products" -d "$product_body")
TICKET_ID=$(echo "$product_response" | jq -r '.data.id')
PRICE_ID=$(echo "$product_response" | jq -r '.data.prices[0].id // empty')
PRICE_VALUE=$(echo "$product_response" | jq -r '.data.prices[0].price // 50')
echo "Ticket ID: $TICKET_ID"
echo "Price ID: $PRICE_ID"

log "Assigning age category rule"
rule_body=$(jq -n '{
  name: "U18/U23",
  calc_mode: "BY_AGE",
  rule: {
    bins: [
      {min: 0, max: 17, label: "U18"},
      {min: 18, max: 23, label: "U23"}
    ]
  },
  version: 1,
  is_active: true
}')
assign_response=$(curl -sS -f -b "$COOKIES" -H 'Content-Type: application/json' -H "${AUTH_HEADER[@]}" \
  -X POST "$API_BASE/events/$EVENT_ID/products/$TICKET_ID/age-category-rule" \
  -d "$rule_body")

echo "Assignment response:"
echo "$assign_response" | jq .

echo "Done. Ticket $TICKET_ID linked to rule $(echo "$assign_response" | jq -r '.rule_id')."

log "Registering 5 users and creating attendees (authenticated)"
for i in {1..5}; do
  user_email="user${i}-${EMAIL_SUFFIX}@example.com"
  reg_body=$(jq -n \
    --arg first "User$i" \
    --arg last "Demo" \
    --arg email "$user_email" \
    --arg pwd "$PASSWORD" \
    '{
      first_name: $first,
      last_name: $last,
      email: $email,
      password: $pwd,
      password_confirmation: $pwd,
      timezone: "UTC",
      currency_code: "USD",
      locale: "en",
      birth_date: "1990-01-01",
      invite_token: null
    }')
  reg_headers=$(mktemp)
  reg_cookies=$(mktemp)
  reg_tmp=$(mktemp)
  reg_status=$(curl -sS -D "$reg_headers" -b "$reg_cookies" -c "$reg_cookies" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -X POST "$API_BASE/auth/register" -d "$reg_body" \
    -o "$reg_tmp" -w "%{http_code}" || true)

  reg_body_out=$(cat "$reg_tmp")
  if [ "$reg_status" != "201" ] && [ "$reg_status" != "200" ]; then
    echo "Registration failed for $user_email (status $reg_status). Response:"
    echo "$reg_body_out" | sed 's/^/  /'
    echo "If registration is disabled, ensure app.disable_registration=false in the API environment."
    rm -f "$reg_headers" "$reg_cookies" "$reg_tmp"
    continue
  fi
  user_token=$(awk 'BEGIN{IGNORECASE=1} /^X-Auth-Token:/ {gsub("\r",""); print $2}' "$reg_headers")
  if [ -z "$user_token" ]; then
    echo "Failed to register or get token for $user_email" >&2
    rm -f "$reg_headers" "$reg_cookies" "$reg_tmp"
    continue
  fi
  rm -f "$reg_tmp"
  user_header=("Authorization: Bearer $user_token")
  attendee_body=$(jq -n \
    --arg email "$user_email" \
    --argjson product_id "$TICKET_ID" \
    --argjson price_id "$PRICE_ID" \
    --arg price "$PRICE_VALUE" \
    '{
      product_id: $product_id,
      product_price_id: $price_id,
      email: $email,
      first_name: "Attendee",
      last_name: "Auth",
      birth_date: "1990-01-01",
      age_category: null,
      club_name: "Auth Club",
      amount_paid: ($price|tonumber),
      send_confirmation_email: false,
      taxes_and_fees: [],
      locale: "en"
    }')
  curl -v -f -b "$reg_cookies" -H 'Content-Type: application/json' -H "${user_header[@]}" \
    -X POST "$API_BASE/events/$EVENT_ID/attendees" -d "$attendee_body"
  rm -f "$reg_headers" "$reg_cookies"
  echo "Created attendee for $user_email"
done

log "Guest checkout x2 (public endpoints)"
for i in {1..2}; do
  guest_email="guest${i}-${EMAIL_SUFFIX}@example.com"
  create_order_body=$(jq -n \
    --argjson product_id "$TICKET_ID" \
    --argjson price_id "$PRICE_ID" \
    '{
      products: [{
        product_id: $product_id,
        quantities: [{price_id: $price_id, quantity: 1}]
      }]
    }')
  order_resp=$(curl -sS -f -D "$HEADERS" -b "$COOKIES" -c "$COOKIES" \
    -H 'Content-Type: application/json' \
    -X POST "$API_BASE/public/events/$EVENT_ID/order" -d "$create_order_body")
  order_short_id=$(echo "$order_resp" | jq -r '.data.short_id // empty')
  if [ -z "$order_short_id" ]; then
    echo "Failed to create public order for guest $i" >&2
    continue
  fi
  complete_body=$(jq -n \
    --arg first "Guest$i" \
    --arg last "Demo" \
    --arg club "Guest Club" \
    --arg email "$guest_email" \
    --argjson price_id "$PRICE_ID" \
    '{
      order: {
        first_name: $first,
        last_name: $last,
        club_name: $club,
        email: $email
      },
      products: [{
        product_price_id: $price_id,
        first_name: $first,
        last_name: $last,
        email: $email,
        club_name: $club
      }]
    }')
  curl -sS -f -b "$COOKIES" -H 'Content-Type: application/json' \
    -X PUT "$API_BASE/public/events/$EVENT_ID/order/$order_short_id" -d "$complete_body" >/dev/null
  echo "Completed guest order for $guest_email"
done
