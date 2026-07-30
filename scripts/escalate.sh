#!/usr/bin/env bash
# Escalation webhook client (TRD Sec 4) -- the single paging path for every
# reason that must wake a human (PR_READY, APP_BOOT_FAILURE, REGRESSION,
# EXHAUSTION). Every future call site sources this one script instead of
# reimplementing HMAC signing per case.
set -euo pipefail

: "${REVI_ESCALATION_WEBHOOK_URL:?REVI_ESCALATION_WEBHOOK_URL is required}"
: "${REVI_ESCALATION_WEBHOOK_SECRET:?REVI_ESCALATION_WEBHOOK_SECRET is required}"
: "${SERVICE_NAME:?SERVICE_NAME is required}"
: "${ALERT_ID:?ALERT_ID is required}"
: "${SEVERITY:?SEVERITY is required}"
: "${REASON:?REASON is required}"
: "${REVI_MODE:?REVI_MODE is required}"
: "${ERROR_SUMMARY:?ERROR_SUMMARY is required}"
: "${ATTEMPTS_MADE:?ATTEMPTS_MADE is required}"

export TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# python3's json module (already present -- python3-dev pulls in python3)
# handles escaping of arbitrary Hermes-generated text safely; hand-rolled
# shell string interpolation into JSON is a correctness/injection risk here.
PAYLOAD="$(python3 -c '
import json, os, sys

# ponytail: flat cap, receiver-agnostic safety net -- Phase 3.5s prompt
# should ask Hermes to stay concise so this rarely triggers; revisit with a
# tighter/looser number if a specific paging tools real limit differs.
MAX_FIELD_LEN = 2000

def cap(s):
    return s if len(s) <= MAX_FIELD_LEN else s[:MAX_FIELD_LEN] + " [truncated]"

json.dump({
    "service_name": os.environ["SERVICE_NAME"],
    "alert_id": os.environ["ALERT_ID"],
    "severity": os.environ["SEVERITY"],
    "reason": os.environ["REASON"],
    "revi_mode": os.environ["REVI_MODE"],
    "pr_url": os.environ.get("PR_URL", ""),
    "error_summary": cap(os.environ["ERROR_SUMMARY"]),
    "confidence_note": cap(os.environ.get("CONFIDENCE_NOTE", "")),
    "attempts_made": int(os.environ["ATTEMPTS_MADE"]),
    "timestamp": os.environ["TIMESTAMP"],
}, sys.stdout)
')"

SIGNATURE="sha256=$(printf '%s' "$PAYLOAD" | openssl dgst -sha256 -hmac "$REVI_ESCALATION_WEBHOOK_SECRET" | awk '{print $2}')"

curl --fail --silent --show-error \
  -X POST "$REVI_ESCALATION_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -H "X-Revi-Signature: $SIGNATURE" \
  -d "$PAYLOAD"
