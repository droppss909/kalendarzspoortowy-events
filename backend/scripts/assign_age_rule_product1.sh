#!/usr/bin/env bash
set -euo pipefail

# Quick assignment of age-category rule to a ticket/product.
# Usage:
#   BASE_URL="http://localhost:8000/api" TOKEN="..." EVENT_ID=123 \
#   TICKET_ID=1 NAME="Rule 2026-01-21" \
#   ./backend/scripts/assign_age_rule_product1.sh
#
# Optionally provide RULE_BINS as JSON array; otherwise default bins are used.

BASE_URL=${BASE_URL:-"http://localhost:8123/api"}
TOKEN=${TOKEN:-""}
EMAIL=${EMAIL:-"mdro@du.pl"}
PASSWORD=${PASSWORD:-"12345678"}
EVENT_ID=${EVENT_ID:-"1"}
TICKET_ID=${TICKET_ID:-"1"}
NAME=${NAME:-"Quick Age Rule"}
RULE_BINS=${RULE_BINS:-""}

if [[ -z "$EVENT_ID" ]]; then
  echo "EVENT_ID is required" >&2
  exit 1
fi

if [[ -z "$TOKEN" ]]; then
  if [[ -z "$EMAIL" || -z "$PASSWORD" ]]; then
    echo "TOKEN is required or provide EMAIL and PASSWORD to login" >&2
    exit 1
  fi
  login_body=$(jq -n \
    --arg email "$EMAIL" \
    --arg pwd "$PASSWORD" \
    '{email:$email,password:$pwd}')
  login_response=$(curl -sS -f \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -X POST "$BASE_URL/auth/login" \
    -d "$login_body")
  TOKEN=$(echo "$login_response" | jq -r '.token // empty')
  if [[ -z "$TOKEN" ]]; then
    echo "Failed to login or extract token. Response:" >&2
    echo "$login_response" >&2
    exit 1
  fi
fi

# Default bins (edit as needed)
if [[ -z "$RULE_BINS" ]]; then
  RULE_BINS='[
    {"min":18,"max":29,"gender":"M","age_category":"M20"},
    {"min":18,"max":29,"gender":"F","age_category":"F20"},
    {"min":30,"max":39,"gender":"M","age_category":"M30"},
    {"min":30,"max":39,"gender":"F","age_category":"F30"},
    {"min":40,"max":120,"gender":"M","age_category":"M40"},
    {"min":40,"max":120,"gender":"F","age_category":"F40"}
  ]'
fi

payload=$(cat <<JSON
{
  "name": "${NAME}",
  "calc_mode": "BY_AGE",
  "rule": {
    "bins": ${RULE_BINS}
  },
  "version": 1,
  "is_active": true
}
JSON
)

curl -sS -X POST "${BASE_URL}/events/${EVENT_ID}/products/${TICKET_ID}/age-category-rule" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${payload}" | jq .
