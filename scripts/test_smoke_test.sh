#!/usr/bin/env bash
# End-to-end test of smoke-test.sh (PLAN 4.1 "done when": a deliberately
# broken boot in the scratch repo pages and never merges). Uses the
# REVI_SMOKE_BUDGET_SECONDS override so the failure scenarios don't burn the
# real 30s production budget.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SMOKE="$SCRIPT_DIR/smoke-test.sh"
FIXTURE_SRC="$SCRIPT_DIR/../fixture-app"

FAILURES=0
PORT_BASE=8890

assert_eq() {
  local actual="$1" expected="$2" label="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "PASS: $label ($expected)"
  else
    echo "FAIL: $label -- expected '$expected', got '$actual'"
    FAILURES=$((FAILURES + 1))
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" label="$3"
  if grep -qF -- "$needle" <<< "$haystack"; then
    echo "PASS: $label"
  else
    echo "FAIL: $label -- expected to find '$needle' in: $haystack"
    FAILURES=$((FAILURES + 1))
  fi
}

# Runs smoke-test.sh against a copy of the fixture app with the given boot
# command/health URL/budget, and sets SMOKE_EXIT/OUTCOME/ESCALATION_PAYLOAD
# for the assertions that follow.
run_scenario() {
  local name="$1" boot_command="$2" health_url="$3" budget="$4"
  echo ""
  echo "=== scenario: $name ==="

  local repo; repo="$(mktemp -d)"
  cp -r "$FIXTURE_SRC" "$repo/fixture-app"

  local recv_port=$((PORT_BASE + 1)); PORT_BASE=$recv_port
  local recv_out; recv_out="$(mktemp)"
  local gh_output; gh_output="$(mktemp)"

  python3 "$SCRIPT_DIR/mock_receiver.py" "smoke-test-secret" "$recv_port" > "$recv_out" 2>&1 &
  local recv_pid=$!
  sleep 0.3

  ( export GITHUB_WORKSPACE="$repo"
    export REVI_BOOT_COMMAND="$boot_command"
    export REVI_HEALTH_URL="$health_url"
    export REVI_SMOKE_BUDGET_SECONDS="$budget"
    export SERVICE_NAME="fixture-svc" ALERT_ID="test-$name"
    export ERROR_SUMMARY="invalid memory address or nil pointer dereference"
    export REVI_MODE="AUTONOMOUS" ATTEMPTS_MADE="1"
    export REVI_ESCALATION_WEBHOOK_URL="http://127.0.0.1:$recv_port"
    export REVI_ESCALATION_WEBHOOK_SECRET="smoke-test-secret"
    export GITHUB_OUTPUT="$gh_output"
    bash "$SMOKE"
  )
  SMOKE_EXIT=$?

  sleep 0.3
  kill "$recv_pid" 2>/dev/null
  wait "$recv_pid" 2>/dev/null

  OUTCOME="$(grep '^outcome=' "$gh_output" 2>/dev/null | cut -d= -f2-)"
  ESCALATION_PAYLOAD="$(grep 'RECEIVED_PAYLOAD' "$recv_out" 2>/dev/null || echo '')"

  rm -rf "$repo" "$recv_out" "$gh_output"
}

### Scenario A: app boots and answers /healthz within budget
run_scenario "healthy" "cd fixture-app && go run ." "http://localhost:8080/healthz" 15
assert_eq "$SMOKE_EXIT" "0" "A: smoke-test.sh exit code"
assert_eq "$OUTCOME" "PASSED" "A: outcome output"
assert_eq "$ESCALATION_PAYLOAD" "" "A: no escalation on healthy boot"

### Scenario B: boot process exits immediately, never listens
run_scenario "exits-immediately" "exit 1" "http://127.0.0.1:19999/healthz" 3
assert_eq "$SMOKE_EXIT" "1" "B: smoke-test.sh exit code"
assert_eq "$OUTCOME" "FAILED" "B: outcome output"
assert_contains "$ESCALATION_PAYLOAD" "\"reason\": \"APP_BOOT_FAILURE\"" "B: escalation reason"
assert_contains "$ESCALATION_PAYLOAD" "\"severity\": \"critical\"" "B: escalation severity"

### Scenario C: process runs but never opens the health port (times out)
run_scenario "never-healthy" "sleep 30" "http://127.0.0.1:19999/healthz" 3
assert_eq "$SMOKE_EXIT" "1" "C: smoke-test.sh exit code"
assert_eq "$OUTCOME" "FAILED" "C: outcome output"
assert_contains "$ESCALATION_PAYLOAD" "\"reason\": \"APP_BOOT_FAILURE\"" "C: escalation reason"

echo ""
if [[ "$FAILURES" -eq 0 ]]; then
  echo "ALL PASS"
  exit 0
else
  echo "$FAILURES FAILURE(S)"
  exit 1
fi
