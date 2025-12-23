#!/usr/bin/env bash
set -euo pipefail

# Smoke test: register user -> create organizer/event/product -> attach age rule -> create attendee -> verify age_category
# Usage: API_BASE=http://localhost:8000 ./backend/scripts/api_age_rule.sh

API_BASE="${API_BASE:-${1:-http://localhost:8000}}"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

log() { printf "${BLUE}==%s==${NC}\n" "$*"; }
ok() { printf "${GREEN}✓ %s${NC}\n" "$*"; }
fail() { printf "${RED}✗ %s${NC}\n" "$*"; exit 1; }

log "Config"
echo "API_BASE=${API_BASE}"
echo

rand_suffix=$((RANDOM%90000+10000))
EMAIL="age_rule_${rand_suffix}@example.com"
PASSWORD="Password123!"
BIRTH_DATE="1995-01-01" # ~29 years, fits ADULT bin below

# Register user
log "Register user"
reg_resp=$(curl -sS -D /tmp/headers.$rand_suffix \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -X POST "${API_BASE}/auth/register" \
  -d "$(jq -n --arg email "$EMAIL" --arg pwd "$PASSWORD" --arg dob "$BIRTH_DATE" '{
    first_name: "Age",
    last_name: "Rule",
    email: $email,
    password: $pwd,
    password_confirmation: $pwd,
    timezone: "UTC",
    currency_code: "USD",
    locale: "en",
    birth_date: $dob
  }')" -o /tmp/body.$rand_suffix -w "%{http_code}")
reg_code="$reg_resp"
reg_body=$(cat /tmp/body.$rand_suffix)
token=$(awk 'BEGIN{IGNORECASE=1} /^X-Auth-Token:/ {gsub("\r",""); print $2}' /tmp/headers.$rand_suffix)
rm -f /tmp/headers.$rand_suffix /tmp/body.$rand_suffix
[ "$reg_code" = "201" ] || [ "$reg_code" = "200" ] || fail "Register failed (HTTP $reg_code): $reg_body"
[ -n "$token" ] || fail "Missing X-Auth-Token header"
ok "Registered $EMAIL"

AUTH_HEADER=("Authorization: Bearer $token")

# Create organizer
log "Create organizer"
org_body=$(jq -n '{name:"Age Rule Org",email:"organizer@example.com",timezone:"UTC",currency:"USD"}')
org_resp=$(curl -sS -w "%{http_code}" -o /tmp/org.$rand_suffix \
  -H "Content-Type: application/json" -H "Accept: application/json" -H "${AUTH_HEADER[@]}" \
  -X POST "${API_BASE}/organizers" -d "$org_body")
org_code="$org_resp"
org_json=$(cat /tmp/org.$rand_suffix)
rm -f /tmp/org.$rand_suffix
[ "$org_code" = "201" ] || [ "$org_code" = "200" ] || fail "Organizer failed (HTTP $org_code): $org_json"
ORG_ID=$(echo "$org_json" | jq -r '.data.id // .id')
ok "Organizer ID $ORG_ID"

# Create event
log "Create event"
START_DATE=$(date -u -d "+1 day" +"%Y-%m-%dT%H:00:00Z" 2>/dev/null || date -u +"%Y-%m-%dT%H:00:00Z")
END_DATE=$(date -u -d "+2 days" +"%Y-%m-%dT%H:00:00Z" 2>/dev/null || date -u +"%Y-%m-%dT%H:00:00Z")
event_body=$(jq -n --arg start "$START_DATE" --arg end "$END_DATE" --argjson org "$ORG_ID" '{
  title:"Age Rule Event",
  description:"Auto test",
  start_date:$start,
  end_date:$end,
  timezone:"UTC",
  currency:"USD",
  organizer_id:$org,
  status:"PUBLISHED"
}')
event_resp=$(curl -sS -w "%{http_code}" -o /tmp/event.$rand_suffix \
  -H "Content-Type: application/json" -H "Accept: application/json" -H "${AUTH_HEADER[@]}" \
  -X POST "${API_BASE}/events" -d "$event_body")
event_code="$event_resp"
event_json=$(cat /tmp/event.$rand_suffix)
rm -f /tmp/event.$rand_suffix
[ "$event_code" = "201" ] || [ "$event_code" = "200" ] || fail "Event failed (HTTP $event_code): $event_json"
EVENT_ID=$(echo "$event_json" | jq -r '.data.id // .id')
ok "Event ID $EVENT_ID"

# Get or create product category
log "Fetch product categories"
cat_json=$(curl -sS -H "${AUTH_HEADER[@]}" -H "Accept: application/json" "${API_BASE}/events/${EVENT_ID}/product-categories")
PRODUCT_CATEGORY_ID=$(echo "$cat_json" | jq -r '.data[0].id // .[0].id // empty')
if [ -z "$PRODUCT_CATEGORY_ID" ]; then
  log "Create default category"
  cat_body=$(jq -n '{name:"Tickets",is_hidden:false}')
  cat_resp=$(curl -sS -w "%{http_code}" -o /tmp/cat.$rand_suffix \
    -H "Content-Type: application/json" -H "Accept: application/json" -H "${AUTH_HEADER[@]}" \
    -X POST "${API_BASE}/events/${EVENT_ID}/product-categories" -d "$cat_body")
  cat_code="$cat_resp"
  cat_json=$(cat /tmp/cat.$rand_suffix)
  rm -f /tmp/cat.$rand_suffix
  [ "$cat_code" = "201" ] || [ "$cat_code" = "200" ] || fail "Category failed (HTTP $cat_code): $cat_json"
  PRODUCT_CATEGORY_ID=$(echo "$cat_json" | jq -r '.data.id // .id')
fi
ok "Product category ID $PRODUCT_CATEGORY_ID"

# Create ticket/product
log "Create ticket"
product_body=$(jq -n --argjson cat "$PRODUCT_CATEGORY_ID" '{
  title:"Age Rule Ticket",
  description:"Auto ticket",
  type:"PAID",
  product_type:"TICKET",
  product_category_id:$cat,
  prices:[{price:50.0,label:null,initial_quantity_available:50}]
}')
prod_resp=$(curl -sS -w "%{http_code}" -o /tmp/prod.$rand_suffix \
  -H "Content-Type: application/json" -H "Accept: application/json" -H "${AUTH_HEADER[@]}" \
  -X POST "${API_BASE}/events/${EVENT_ID}/products" -d "$product_body")
prod_code="$prod_resp"
prod_json=$(cat /tmp/prod.$rand_suffix)
rm -f /tmp/prod.$rand_suffix
[ "$prod_code" = "201" ] || [ "$prod_code" = "200" ] || fail "Product failed (HTTP $prod_code): $prod_json"
TICKET_ID=$(echo "$prod_json" | jq -r '.data.id // .id')
PRICE_ID=$(echo "$prod_json" | jq -r '.data.prices[0].id // .prices[0].id')
PRICE_VALUE=$(echo "$prod_json" | jq -r '.data.prices[0].price // 50')
ok "Ticket $TICKET_ID, price $PRICE_ID"

# Assign age category rule (5 bins)
log "Assign age rule to ticket"
rule_body=$(jq -n '{
  name:"Multibin Rule",
  calc_mode:"BY_AGE",
  rule:{bins:[
    {min:0,max:11,label:"U12"},
    {min:12,max:15,label:"U16"},
    {min:16,max:19,label:"U20"},
    {min:20,max:29,label:"U30"},
    {min:30,max:120,label:"SENIOR"}
  ]},
  version:1,
  is_active:true
}')
rule_resp=$(curl -sS -w "%{http_code}" -o /tmp/rule.$rand_suffix \
  -H "Content-Type: application/json" -H "Accept: application/json" -H "${AUTH_HEADER[@]}" \
  -X POST "${API_BASE}/events/${EVENT_ID}/products/${TICKET_ID}/age-category-rule" -d "$rule_body")
rule_code="$rule_resp"
rule_json=$(cat /tmp/rule.$rand_suffix)
rm -f /tmp/rule.$rand_suffix
[ "$rule_code" = "201" ] || [ "$rule_code" = "200" ] || fail "Age rule assignment failed (HTTP $rule_code): $rule_json"
RULE_ID=$(echo "$rule_json" | jq -r '.rule_id // .id')
ok "Rule assigned (rule_id=$RULE_ID)"

# Create multiple attendees to hit all bins
log "Create 10 attendees with expected categories (updating user birth_date before each create)"
declare -a births=(
  "2015-01-01:U12"
  "2012-06-15:U16"
  "2010-03-10:U16"
  "2008-08-20:U20"
  "2006-12-05:U20"
  "2004-07-07:U30"
  "1998-09-09:U30"
  "1995-11-11:SENIOR"
  "1985-04-04:SENIOR"
  "1975-05-05:SENIOR"
)

idx=0
for pair in "${births[@]}"; do
  birth="${pair%%:*}"
  expected="${pair##*:}"
  idx=$((idx+1))

  # Update user profile so CreateAttendeeAction pulls this DOB from the account
  update_body=$(jq -n --arg dob "$birth" --arg email "$EMAIL" '{
    first_name:"Age",
    last_name:"Rule",
    email:$email,
    timezone:"UTC",
    locale:"en",
    birth_date:$dob
  }')
  upd_resp=$(curl -sS -w "%{http_code}" -o /tmp/upd.${rand_suffix}.${idx} \
    -H "Content-Type: application/json" -H "Accept: application/json" -H "${AUTH_HEADER[@]}" \
    -X PUT "${API_BASE}/users/me" -d "$update_body")
  upd_code="$upd_resp"
  upd_json=$(cat /tmp/upd.${rand_suffix}.${idx})
  rm -f /tmp/upd.${rand_suffix}.${idx}
  [ "$upd_code" = "200" ] || fail "Update user birth_date failed (HTTP $upd_code): $upd_json"

  att_body=$(jq -n --arg email "$EMAIL" --argjson pid "$TICKET_ID" --argjson price "$PRICE_ID" --arg price_val "$PRICE_VALUE" --arg dob "$birth" '{
    product_id:$pid,
    product_price_id:$price,
    amount_paid:($price_val|tonumber),
    send_confirmation_email:false,
    taxes_and_fees:[],
    email:$email,
    first_name:"Auto",
    last_name:"User",
    birth_date:$dob,
    club_name:"Age Club",
    locale:"en"
  }')
  att_resp=$(curl -sS -w "%{http_code}" -o /tmp/att.${rand_suffix}.${idx} \
    -H "Content-Type: application/json" -H "Accept: application/json" -H "${AUTH_HEADER[@]}" \
    -X POST "${API_BASE}/events/${EVENT_ID}/attendees" -d "$att_body")
  att_code="$att_resp"
  att_json=$(cat /tmp/att.${rand_suffix}.${idx})
  rm -f /tmp/att.${rand_suffix}.${idx}
  [ "$att_code" = "201" ] || fail "Attendee #$idx failed (HTTP $att_code): $att_json"
  AGE_CATEGORY=$(echo "$att_json" | jq -r '.data.age_category // .age_category // empty')
  if [ "$AGE_CATEGORY" != "$expected" ]; then
    fail "Attendee #$idx birth_date=$birth expected=$expected got='${AGE_CATEGORY:-<empty>}'"
  fi
  ok "Attendee #$idx birth_date=$birth age_category=$AGE_CATEGORY"
done

echo
ok "All steps passed for ${EMAIL}"
