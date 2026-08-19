#!/usr/bin/env bash
# Synthetic smoke testing (TRD FR-03, PLAN 4.1). Boots the app in the
# background via REVI_BOOT_COMMAND and polls REVI_HEALTH_URL until it
# answers or the budget runs out (default 30s per FR-03's NFR). A boot
# failure pages immediately via escalate.sh -- structurally separate from
# the Slack digest so it breaks through Do Not Disturb, per TRD FR-03.
set -uo pipefail  # not -e: the health poll loop expects curl to fail repeatedly

: "${GITHUB_WORKSPACE:?GITHUB_WORKSPACE is required}"
: "${REVI_BOOT_COMMAND:?REVI_BOOT_COMMAND is required}"
: "${REVI_HEALTH_URL:?REVI_HEALTH_URL is required}"
: "${SERVICE_NAME:?SERVICE_NAME is required}"
: "${ALERT_ID:?ALERT_ID is required}"
: "${ERROR_SUMMARY:?ERROR_SUMMARY is required}"
: "${REVI_MODE:?REVI_MODE is required}"
: "${ATTEMPTS_MADE:?ATTEMPTS_MADE is required}"
: "${REVI_ESCALATION_WEBHOOK_URL:?REVI_ESCALATION_WEBHOOK_URL is required}"
: "${REVI_ESCALATION_WEBHOOK_SECRET:?REVI_ESCALATION_WEBHOOK_SECRET is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ponytail: override hook for tests only, so failure scenarios don't burn
# the real 30s budget; never set in the real workflow.
BUDGET_SECONDS="${REVI_SMOKE_BUDGET_SECONDS:-30}"

cd "$GITHUB_WORKSPACE"

# Backgrounded without job control (no `set -m`), so this PID is whatever
# process runs REVI_BOOT_COMMAND directly -- for `go run`, the go command
# forwards termination signals to the compiled binary it launches, so
# killing this PID stops the server too, not just the go tool.
eval "$REVI_BOOT_COMMAND" &
BOOT_PID=$!

cleanup() {
  kill "$BOOT_PID" 2>/dev/null
  wait "$BOOT_PID" 2>/dev/null
}
trap cleanup EXIT

SECONDS=0
BOOTED=0
while (( SECONDS < BUDGET_SECONDS )); do
  if curl --fail --silent --show-error --max-time 2 -o /dev/null "$REVI_HEALTH_URL"; then
    BOOTED=1
    break
  fi
  # A boot process that already exited can never pass a health check --
  # fail fast instead of burning the rest of the budget polling nothing.
  if ! kill -0 "$BOOT_PID" 2>/dev/null; then
    echo "smoke-test: boot process exited before becoming healthy" >&2
    break
  fi
  sleep 1
done

if [[ "$BOOTED" -eq 1 ]]; then
  echo "smoke-test: app healthy after ${SECONDS}s"
  echo "outcome=PASSED" >> "${GITHUB_OUTPUT:-/dev/null}"
  exit 0
fi

echo "smoke-test: app did not become healthy within ${BUDGET_SECONDS}s" >&2
{
  echo "outcome=FAILED"
  echo "escalation_reason=APP_BOOT_FAILURE"
  echo "failure_stage=boot"
  echo "failure_classification=remediation_failure"
} >> "${GITHUB_OUTPUT:-/dev/null}"

SERVICE_NAME="$SERVICE_NAME" \
SEVERITY="critical" \
REASON="APP_BOOT_FAILURE" \
REVI_MODE="$REVI_MODE" \
ERROR_SUMMARY="$ERROR_SUMMARY" \
CONFIDENCE_NOTE="Hermes's patch compiled and passed its sibling test, but the app failed to boot / answer $REVI_HEALTH_URL within ${BUDGET_SECONDS}s." \
ATTEMPTS_MADE="$ATTEMPTS_MADE" \
ALERT_ID="$ALERT_ID" \
bash "$SCRIPT_DIR/escalate.sh"

exit 1
