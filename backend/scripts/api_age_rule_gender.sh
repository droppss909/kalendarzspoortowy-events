#!/usr/bin/env bash
set -euo pipefail

# Smoke test for age-category rules with gender:
# - Register user with gender
# - Create organizer/event/product
# - Assign age rule bins that include gender filters
# - Create attendees (authenticated male, guest female) and verify age_category is prefixed (M/F)
# Usage: API_BASE=http://localhost:8000 ./backend/scripts/api_age_rule_gender.sh

API_BASE="${API_BASE:-${1:-http://localhost:8000}}"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { printf "${BLUE}==%s==${NC}\n" "$*"; }
ok() { printf "${GREEN}✓ %s${NC}\n" "$*"; }
fail() { printf "${RED}✗ %s${NC}\n" "$*"; exit 1; }

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

log "Config"
echo "API_BASE=${API_BASE}"
echo

rand_suffix=$((RANDOM%90000+10000))
EMAIL="gender_rule_${rand_suffix}@example.com"
PASSWORD="Password123!"
USER_BIRTH_DATE="1992-01-01" # ~32 -> should hit 30 bin
USER_GENDER="M"

# Register user with gender
log "Register user"
reg_payload=$(jq -n --arg email "$EMAIL" --arg pwd "$PASSWORD" --arg dob "$USER_BIRTH_DATE" --arg gender "$USER_GENDER" '{
  first_name:"Gender",
  last_name:"Rule",
  email:$email,
  password:$pwd,
  password_confirmation:$pwd,
  timezone:"UTC",
  currency_code:"USD",
  locale:"en",
  birth_date:$dob,
  gender:$gender
}')
reg_resp=$(curl -sS -D /tmp/headers.$rand_suffix \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -X POST "${API_BASE}/auth/register" \
  -d "$reg_payload" -o /tmp/body.$rand_suffix -w "%{http_code}")
reg_code="$reg_resp"
reg_body=$(cat /tmp/body.$rand_suffix)
token=$(awk 'BEGIN{IGNORECASE=1} /^X-Auth-Token:/ {gsub("\r",""); print $2}' /tmp/headers.$rand_suffix)
rm -f /tmp/headers.$rand_suffix /tmp/body.$rand_suffix
[ "$reg_code" = "201" ] || [ "$reg_code" = "200" ] || fail "Register failed (HTTP $reg_code): $reg_body"
[ -n "$token" ] || fail "Missing X-Auth-Token header"
ok "Registered $EMAIL (gender=$USER_GENDER)"

AUTH_HEADER=("Authorization: Bearer $token")

# Create organizer
log "Create organizer"
org_body=$(jq -n '{name:"Gender Org",email:"organizer@example.com",timezone:"UTC",currency:"USD"}')
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
  title:"Gender Age Rule Event",
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

# Fetch/create product category
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
  title:"Gender Ticket",
  description:"Auto ticket",
  type:"PAID",
  product_type:"TICKET",
  product_category_id:$cat,
  prices:[{price:40.0,label:null,initial_quantity_available:20}]
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
PRICE_VALUE=$(echo "$prod_json" | jq -r '.data.prices[0].price // 40')
ok "Ticket $TICKET_ID, price $PRICE_ID"

# Assign age rule with gender-aware bins
log "Assign age rule to ticket"
rule_body=$(jq -n '{
  name:"Gendered Rule",
  calc_mode:"BY_AGE",
  rule:{bins:[
    {min:18,max:29,gender:"M",age_category:"M20"},
    {min:18,max:29,gender:"F",age_category:"F20"},
    {min:30,max:39,gender:"M",age_category:"M30"},
    {min:30,max:39,gender:"F",age_category:"F30"},
    {min:40,max:120,gender:"M",age_category:"M40"},
    {min:40,max:120,gender:"F",age_category:"F40"}
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
ok "Rule assigned"

# Authenticated attendee (gender from account -> expect M30)
log "Create authenticated attendee (gender=M, ~32y -> expect M30)"
att_body_auth=$(jq -n --argjson pid "$TICKET_ID" --argjson price "$PRICE_ID" --arg price_val "$PRICE_VALUE" --arg dob "$USER_BIRTH_DATE" --arg gender "$USER_GENDER" '{
  product_id:$pid,
  product_price_id:$price,
  amount_paid:($price_val|tonumber),
  send_confirmation_email:false,
  taxes_and_fees:[],
  first_name:"Auth",
  last_name:"User",
  email:"unused@example.com", # overridden by server for authed user
  birth_date:$dob,
  gender:$gender,
  club_name:"Gender Club",
  locale:"en"
}')
att_resp_auth=$(curl -sS -w "%{http_code}" -o /tmp/att_auth.$rand_suffix \
  -H "Content-Type: application/json" -H "Accept: application/json" -H "${AUTH_HEADER[@]}" \
  -X POST "${API_BASE}/events/${EVENT_ID}/attendees" -d "$att_body_auth")
att_code_auth="$att_resp_auth"
att_json_auth=$(cat /tmp/att_auth.$rand_suffix)
rm -f /tmp/att_auth.$rand_suffix
[ "$att_code_auth" = "201" ] || fail "Authenticated attendee failed (HTTP $att_code_auth): $att_json_auth"
AGE_CATEGORY_AUTH=$(echo "$att_json_auth" | jq -r '.data.age_category // .age_category // empty')
[ "$AGE_CATEGORY_AUTH" = "M30" ] || fail "Authenticated attendee expected age_category=M30 got='${AGE_CATEGORY_AUTH:-<empty>}'"
ok "Authenticated attendee age_category=$AGE_CATEGORY_AUTH"

# Guest attendee with gender F (~34y -> expect F30)
log "Create guest attendee (gender=F, ~34y -> expect F30)"
guest_birth="1990-05-05"
att_body_guest=$(jq -n --argjson pid "$TICKET_ID" --argjson price "$PRICE_ID" --arg price_val "$PRICE_VALUE" --arg dob "$guest_birth" '{
  product_id:$pid,
  product_price_id:$price,
  amount_paid:($price_val|tonumber),
  send_confirmation_email:false,
  taxes_and_fees:[],
  email:"guest_'$rand_suffix'@example.com",
  first_name:"Guest",
  last_name:"Female",
  birth_date:$dob,
  gender:"F",
  club_name:"Gender Club",
  locale:"en"
}')
att_resp_guest=$(curl -sS -w "%{http_code}" -o /tmp/att_guest.$rand_suffix \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -X POST "${API_BASE}/public/events/${EVENT_ID}/attendees" -d "$att_body_guest")
att_code_guest="$att_resp_guest"
att_json_guest=$(cat /tmp/att_guest.$rand_suffix)
rm -f /tmp/att_guest.$rand_suffix
[ "$att_code_guest" = "201" ] || fail "Guest attendee failed (HTTP $att_code_guest): $att_json_guest"
AGE_CATEGORY_GUEST=$(echo "$att_json_guest" | jq -r '.data.age_category // .age_category // empty')
[ "$AGE_CATEGORY_GUEST" = "F30" ] || fail "Guest attendee expected age_category=F30 got='${AGE_CATEGORY_GUEST:-<empty>}'"
ok "Guest attendee age_category=$AGE_CATEGORY_GUEST"

# Extra guest attendees for more coverage (public, different ages/genders)
log "Create additional guest attendees on event #1"
declare -a guest_cases=(
  "male_25:1999-01-01:M20:M"
  "female_25:1998-06-01:F20:F"
  "male_45:1980-02-02:M40:M"
  "female_42:1982-03-03:F40:F"
)
gc_idx=0
for case in "${guest_cases[@]}"; do
  label="${case%%:*}"
  rest="${case#*:}"
  dob="${rest%%:*}"
  rest="${rest#*:}"
  expected="${rest%%:*}"
  gender="${rest##*:}"
  gc_idx=$((gc_idx+1))

  body=$(jq -n --argjson pid "$TICKET_ID" --argjson price "$PRICE_ID" --arg price_val "$PRICE_VALUE" --arg dob "$dob" --arg gender "$gender" --arg label "$label" '{
    product_id:$pid,
    product_price_id:$price,
    amount_paid:($price_val|tonumber),
    send_confirmation_email:false,
    taxes_and_fees:[],
    email:("guest_" + $label + "@example.com"),
    first_name:"GuestExtra",
    last_name:$label,
    birth_date:$dob,
    gender:$gender,
    club_name:"Gender Club",
    locale:"en"
  }')

  resp=$(curl -sS -w "%{http_code}" -o /tmp/att_guest_extra.${rand_suffix}.${gc_idx} \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    -X POST "${API_BASE}/public/events/${EVENT_ID}/attendees" -d "$body")
  code="$resp"
  json=$(cat /tmp/att_guest_extra.${rand_suffix}.${gc_idx})
  rm -f /tmp/att_guest_extra.${rand_suffix}.${gc_idx}
  [ "$code" = "201" ] || fail "Guest attendee $label failed (HTTP $code): $json"
  age_cat=$(echo "$json" | jq -r '.data.age_category // .age_category // empty')
  [ "$age_cat" = "$expected" ] || fail "Guest attendee $label expected age_category=$expected got='${age_cat:-<empty>}'"
  ok "Guest attendee $label age_category=$age_cat"
done

# Additional scenarios: register another user + event and ensure attendees map correctly
log "Register second user (gender=F)"
rand_suffix2=$((RANDOM%90000+10000))
EMAIL2="gender_rule_${rand_suffix2}@example.com"
PASSWORD2="Password123!"
USER2_BIRTH_DATE="1996-02-02" # ~28 -> expect F20
USER2_GENDER="F"

reg_payload2=$(jq -n --arg email "$EMAIL2" --arg pwd "$PASSWORD2" --arg dob "$USER2_BIRTH_DATE" --arg gender "$USER2_GENDER" '{
  first_name:"Gender2",
  last_name:"Rule2",
  email:$email,
  password:$pwd,
  password_confirmation:$pwd,
  timezone:"UTC",
  currency_code:"USD",
  locale:"en",
  birth_date:$dob,
  gender:$gender
}')
reg_resp2=$(curl -sS -D /tmp/headers2.$rand_suffix2 \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -X POST "${API_BASE}/auth/register" \
  -d "$reg_payload2" -o /tmp/body2.$rand_suffix2 -w "%{http_code}")
reg_code2="$reg_resp2"
reg_body2=$(cat /tmp/body2.$rand_suffix2)
token2=$(awk 'BEGIN{IGNORECASE=1} /^X-Auth-Token:/ {gsub("\r",""); print $2}' /tmp/headers2.$rand_suffix2)
rm -f /tmp/headers2.$rand_suffix2 /tmp/body2.$rand_suffix2
[ "$reg_code2" = "201" ] || [ "$reg_code2" = "200" ] || fail "Register #2 failed (HTTP $reg_code2): $reg_body2"
[ -n "$token2" ] || fail "Missing X-Auth-Token header for user #2"
ok "Registered $EMAIL2 (gender=$USER2_GENDER)"

AUTH_HEADER2=("Authorization: Bearer $token2")

log "Create organizer #2"
org_body2=$(jq -n '{name:"Gender Org2",email:"organizer2@example.com",timezone:"UTC",currency:"USD"}')
org_resp2=$(curl -sS -w "%{http_code}" -o /tmp/org2.$rand_suffix2 \
  -H "Content-Type: application/json" -H "Accept: application/json" -H "${AUTH_HEADER2[@]}" \
  -X POST "${API_BASE}/organizers" -d "$org_body2")
org_code2="$org_resp2"
org_json2=$(cat /tmp/org2.$rand_suffix2)
rm -f /tmp/org2.$rand_suffix2
[ "$org_code2" = "201" ] || [ "$org_code2" = "200" ] || fail "Organizer #2 failed (HTTP $org_code2): $org_json2"
ORG_ID2=$(echo "$org_json2" | jq -r '.data.id // .id')
ok "Organizer #2 ID $ORG_ID2"

log "Create event #2"
START_DATE2=$(date -u -d "+1 day" +"%Y-%m-%dT%H:00:00Z" 2>/dev/null || date -u +"%Y-%m-%dT%H:00:00Z")
END_DATE2=$(date -u -d "+2 days" +"%Y-%m-%dT%H:00:00Z" 2>/dev/null || date -u +"%Y-%m-%dT%H:00:00Z")
event_body2=$(jq -n --arg start "$START_DATE2" --arg end "$END_DATE2" --argjson org "$ORG_ID2" '{
  title:"Gender Age Rule Event 2",
  description:"Auto test 2",
  start_date:$start,
  end_date:$end,
  timezone:"UTC",
  currency:"USD",
  organizer_id:$org,
  status:"PUBLISHED"
}')
event_resp2=$(curl -sS -w "%{http_code}" -o /tmp/event2.$rand_suffix2 \
  -H "Content-Type: application/json" -H "Accept: application/json" -H "${AUTH_HEADER2[@]}" \
  -X POST "${API_BASE}/events" -d "$event_body2")
event_code2="$event_resp2"
event_json2=$(cat /tmp/event2.$rand_suffix2)
rm -f /tmp/event2.$rand_suffix2
[ "$event_code2" = "201" ] || [ "$event_code2" = "200" ] || fail "Event #2 failed (HTTP $event_code2): $event_json2"
EVENT_ID2=$(echo "$event_json2" | jq -r '.data.id // .id')
ok "Event #2 ID $EVENT_ID2"

log "Create product category #2"
cat_body2=$(jq -n '{name:"Tickets2",is_hidden:false}')
cat_resp2=$(curl -sS -w "%{http_code}" -o /tmp/cat2.$rand_suffix2 \
  -H "Content-Type: application/json" -H "Accept: application/json" -H "${AUTH_HEADER2[@]}" \
  -X POST "${API_BASE}/events/${EVENT_ID2}/product-categories" -d "$cat_body2")
cat_code2="$cat_resp2"
cat_json2=$(cat /tmp/cat2.$rand_suffix2)
rm -f /tmp/cat2.$rand_suffix2
[ "$cat_code2" = "201" ] || [ "$cat_code2" = "200" ] || fail "Category #2 failed (HTTP $cat_code2): $cat_json2"
PRODUCT_CATEGORY_ID2=$(echo "$cat_json2" | jq -r '.data.id // .id')
ok "Product category #2 ID $PRODUCT_CATEGORY_ID2"

log "Create ticket #2"
product_body2=$(jq -n --argjson cat "$PRODUCT_CATEGORY_ID2" '{
  title:"Gender Ticket 2",
  description:"Auto ticket 2",
  type:"PAID",
  product_type:"TICKET",
  product_category_id:$cat,
  prices:[{price:30.0,label:null,initial_quantity_available:20}]
}')
prod_resp2=$(curl -sS -w "%{http_code}" -o /tmp/prod2.$rand_suffix2 \
  -H "Content-Type: application/json" -H "Accept: application/json" -H "${AUTH_HEADER2[@]}" \
  -X POST "${API_BASE}/events/${EVENT_ID2}/products" -d "$product_body2")
prod_code2="$prod_resp2"
prod_json2=$(cat /tmp/prod2.$rand_suffix2)
rm -f /tmp/prod2.$rand_suffix2
[ "$prod_code2" = "201" ] || [ "$prod_code2" = "200" ] || fail "Product #2 failed (HTTP $prod_code2): $prod_json2"
TICKET_ID2=$(echo "$prod_json2" | jq -r '.data.id // .id')
PRICE_ID2=$(echo "$prod_json2" | jq -r '.data.prices[0].id // .prices[0].id')
PRICE_VALUE2=$(echo "$prod_json2" | jq -r '.data.prices[0].price // 30')
ok "Ticket #2 $TICKET_ID2, price $PRICE_ID2"

log "Assign age rule to ticket #2"
rule_resp2=$(curl -sS -w "%{http_code}" -o /tmp/rule2.$rand_suffix2 \
  -H "Content-Type: application/json" -H "Accept: application/json" -H "${AUTH_HEADER2[@]}" \
  -X POST "${API_BASE}/events/${EVENT_ID2}/products/${TICKET_ID2}/age-category-rule" -d "$rule_body")
rule_code2="$rule_resp2"
rule_json2=$(cat /tmp/rule2.$rand_suffix2)
rm -f /tmp/rule2.$rand_suffix2
[ "$rule_code2" = "201" ] || [ "$rule_code2" = "200" ] || fail "Age rule #2 failed (HTTP $rule_code2): $rule_json2"
ok "Rule #2 assigned"

log "Create authenticated attendee #2 (gender=F, ~28y -> expect F20)"
att_body_auth2=$(jq -n --argjson pid "$TICKET_ID2" --argjson price "$PRICE_ID2" --arg price_val "$PRICE_VALUE2" --arg dob "$USER2_BIRTH_DATE" --arg gender "$USER2_GENDER" '{
  product_id:$pid,
  product_price_id:$price,
  amount_paid:($price_val|tonumber),
  send_confirmation_email:false,
  taxes_and_fees:[],
  first_name:"Auth2",
  last_name:"User2",
  email:"unused@example.com",
  birth_date:$dob,
  gender:$gender,
  club_name:"Gender Club",
  locale:"en"
}')
att_resp_auth2=$(curl -sS -w "%{http_code}" -o /tmp/att_auth2.$rand_suffix2 \
  -H "Content-Type: application/json" -H "Accept: application/json" -H "${AUTH_HEADER2[@]}" \
  -X POST "${API_BASE}/events/${EVENT_ID2}/attendees" -d "$att_body_auth2")
att_code_auth2="$att_resp_auth2"
att_json_auth2=$(cat /tmp/att_auth2.$rand_suffix2)
rm -f /tmp/att_auth2.$rand_suffix2
[ "$att_code_auth2" = "201" ] || fail "Authenticated attendee #2 failed (HTTP $att_code_auth2): $att_json_auth2"
AGE_CATEGORY_AUTH2=$(echo "$att_json_auth2" | jq -r '.data.age_category // .age_category // empty')
[ "$AGE_CATEGORY_AUTH2" = "F20" ] || fail "Authenticated attendee #2 expected age_category=F20 got='${AGE_CATEGORY_AUTH2:-<empty>}'"
ok "Authenticated attendee #2 age_category=$AGE_CATEGORY_AUTH2"

log "Create guest attendee #2 (gender=M, ~44y -> expect M40)"
guest_birth2="1980-03-03"
att_body_guest2=$(jq -n --argjson pid "$TICKET_ID2" --argjson price "$PRICE_ID2" --arg price_val "$PRICE_VALUE2" --arg dob "$guest_birth2" '{
  product_id:$pid,
  product_price_id:$price,
  amount_paid:($price_val|tonumber),
  send_confirmation_email:false,
  taxes_and_fees:[],
  email:"guest2_'$rand_suffix2'@example.com",
  first_name:"Guest2",
  last_name:"Male",
  birth_date:$dob,
  gender:"M",
  club_name:"Gender Club",
  locale:"en"
}')
att_resp_guest2=$(curl -sS -w "%{http_code}" -o /tmp/att_guest2.$rand_suffix2 \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -X POST "${API_BASE}/public/events/${EVENT_ID2}/attendees" -d "$att_body_guest2")
att_code_guest2="$att_resp_guest2"
att_json_guest2=$(cat /tmp/att_guest2.$rand_suffix2)
rm -f /tmp/att_guest2.$rand_suffix2
[ "$att_code_guest2" = "201" ] || fail "Guest attendee #2 failed (HTTP $att_code_guest2): $att_json_guest2"
AGE_CATEGORY_GUEST2=$(echo "$att_json_guest2" | jq -r '.data.age_category // .age_category // empty')
[ "$AGE_CATEGORY_GUEST2" = "M40" ] || fail "Guest attendee #2 expected age_category=M40 got='${AGE_CATEGORY_GUEST2:-<empty>}'"
ok "Guest attendee #2 age_category=$AGE_CATEGORY_GUEST2"

echo
ok "Gender-aware age rule flow passed for ${EMAIL}"
