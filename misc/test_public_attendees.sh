#!/usr/bin/env bash

# Simple check for the public attendees endpoint.
# Usage: BASE_URL=http://localhost:8000/api/public misc/test_public_attendees.sh <event_id>

set -euo pipefail

EVENT_ID="${1:-}"
BASE_URL="${BASE_URL:-http://localhost:8123/api/public}"

if [[ -z "${EVENT_ID}" ]]; then
  echo "Usage: BASE_URL=http://localhost:8123/api/public $0 <event_id>"
  exit 1
fi

response_body="$(mktemp)"
trap 'rm -f "${response_body}"' EXIT

http_status="$(
  curl -sS -w "%{http_code}" -o "${response_body}" \
    "${BASE_URL}/events/${EVENT_ID}/attendees"
)"

if [[ "${http_status}" != "200" ]]; then
  echo "Request failed (status ${http_status})"
  cat "${response_body}"
  exit 1
fi

python3 - "${response_body}" <<'PY'
import json
import sys

path = sys.argv[1]
data = json.load(open(path))

if "data" not in data or not isinstance(data["data"], list):
    raise SystemExit("Response missing 'data' array")

if data["data"]:
    sample = data["data"][0]
    for key in ("first_name", "last_name", "club_name", "age_category"):
        if key not in sample:
            raise SystemExit(f"Sample attendee missing key: {key}")

print("✅ Public attendees endpoint looks healthy (club and age_category present).", data)
PY
