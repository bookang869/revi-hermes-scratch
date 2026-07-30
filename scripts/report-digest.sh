#!/usr/bin/env bash
# Digest reporting client (TRD Sec 4) -- called as an always()-guarded final
# step of hermes-triage.yml so every run reports its outcome, success or
# failure, and the morning digest never silently omits a run.
set -euo pipefail

: "${REVI_DIGEST_WEBHOOK_URL:?REVI_DIGEST_WEBHOOK_URL is required}"
: "${REVI_WEBHOOK_SECRET:?REVI_WEBHOOK_SECRET is required}"
: "${ALERT_ID:?ALERT_ID is required}"
: "${REVI_MODE:?REVI_MODE is required}"
: "${OUTCOME:?OUTCOME is required}"
: "${SUMMARY:?SUMMARY is required}"

export DIGEST_DATE="${DIGEST_DATE:-$(date -u +%Y-%m-%d)}"

# Same X-Revi-Signature: sha256=<hex HMAC> scheme as escalate.sh, but keyed
# by REVI_WEBHOOK_SECRET -- this endpoint reuses the Bearer-token secret from
# /v1/alerts as its HMAC key (gateway/internal/digest/handler.go), not the
# separate REVI_ESCALATION_WEBHOOK_SECRET.
PAYLOAD="$(python3 -c '
import json, os, sys
json.dump({
    "alert_id": os.environ["ALERT_ID"],
    "revi_mode": os.environ["REVI_MODE"],
    "outcome": os.environ["OUTCOME"],
    "summary": os.environ["SUMMARY"],
    "digest_date": os.environ["DIGEST_DATE"],
}, sys.stdout)
')"

SIGNATURE="sha256=$(printf '%s' "$PAYLOAD" | openssl dgst -sha256 -hmac "$REVI_WEBHOOK_SECRET" | awk '{print $2}')"

curl --fail --silent --show-error \
  -X POST "$REVI_DIGEST_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -H "X-Revi-Signature: $SIGNATURE" \
  -d "$PAYLOAD"
