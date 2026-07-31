#!/usr/bin/env bash
# End-to-end test of hermes-wrapper.sh (PLAN 3.5 "done when": loop runs
# against a seeded bug; a forced-failure run pages with EXHAUSTION after
# exactly 3 attempts). Uses fake-agent.sh instead of real Hermes so this
# costs nothing and is fully deterministic.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER="$SCRIPT_DIR/hermes-wrapper.sh"
FAKE_AGENT="$SCRIPT_DIR/fake-agent.sh"
FIXTURE_SRC="$SCRIPT_DIR/../fixture-app"

FAILURES=0
RECEIVER_PORT=8770

assert_eq() {
  local actual="$1" expected="$2" label="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "PASS: $label ($expected)"
  else
    echo "FAIL: $label -- expected '$expected', got '$actual'"
    FAILURES=$((FAILURES + 1))
  fi
}

# Sets up a throwaway git repo with the fixture app + scripts, runs the
# wrapper, and echoes GITHUB_OUTPUT's contents plus whether escalate.sh's
# target received a call.
run_scenario() {
  local name="$1" revi_mode="$2" agent_mode_env="$3"
  echo ""
  echo "=== scenario: $name ==="

  local repo; repo="$(mktemp -d)"
  cp -r "$FIXTURE_SRC" "$repo/fixture-app"
  mkdir -p "$repo/scripts"
  cp "$SCRIPT_DIR/detect-test-framework.sh" "$SCRIPT_DIR/escalate.sh" "$repo/scripts/"
  ( cd "$repo" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -qm seed )

  local gh_output; gh_output="$(mktemp)"
  local counter_file; counter_file="$(mktemp)"; rm -f "$counter_file"
  local receiver_out; receiver_out="$(mktemp)"
  # Outside $repo deliberately: the wrapper runs `git clean -fd` inside
  # GITHUB_WORKSPACE on every attempt, which would delete this log itself if
  # it lived inside the repo it's cleaning.
  local wrapper_log; wrapper_log="$(mktemp)"

  RECEIVER_PORT=$((RECEIVER_PORT + 1))
  python3 "$SCRIPT_DIR/mock_receiver.py" "wrapper-test-secret" "$RECEIVER_PORT" > "$receiver_out" 2>&1 &
  local recv_pid=$!
  sleep 0.3

  ( eval "$agent_mode_env"
    export GITHUB_WORKSPACE="$repo"
    export GITHUB_OUTPUT="$gh_output"
    export TRACE_ID="trace-1" ALERT_ID="test-$name" SERVICE_NAME="fixture-svc"
    export ERROR_SUMMARY="invalid memory address or nil pointer dereference"
    export REVI_MODE="$revi_mode"
    export REVI_AGENT_COMMAND="bash $FAKE_AGENT"
    export FIXTURE_APP_DIR="$repo/fixture-app"
    export FAKE_AGENT_COUNTER_FILE="$counter_file"
    export REVI_ESCALATION_WEBHOOK_URL="http://127.0.0.1:$RECEIVER_PORT"
    export REVI_ESCALATION_WEBHOOK_SECRET="wrapper-test-secret"
    bash "$WRAPPER" > "$wrapper_log" 2>&1
  )
  local wrapper_exit=$?

  # handle_request() blocks forever if escalate.sh never gets called (the
  # success scenarios), so don't wait on it -- give it a brief moment to
  # finish handling any in-flight request, then kill it unconditionally.
  sleep 0.3
  kill "$recv_pid" 2>/dev/null
  wait "$recv_pid" 2>/dev/null

  echo "--- wrapper.log ---"
  cat "$wrapper_log" 2>/dev/null
  echo "--- outputs ---"
  cat "$gh_output" 2>/dev/null

  OUTCOME="$(grep '^outcome=' "$gh_output" 2>/dev/null | cut -d= -f2-)"
  ATTEMPTS="$(grep '^attempts_made=' "$gh_output" 2>/dev/null | cut -d= -f2-)"
  WRAPPER_EXIT="$wrapper_exit"
  ESCALATED="$(grep -c 'RECEIVED_PAYLOAD' "$receiver_out" 2>/dev/null)"
  ESCALATION_PAYLOAD="$(grep 'RECEIVED_PAYLOAD' "$receiver_out" 2>/dev/null || echo '')"

  rm -rf "$repo" "$gh_output" "$counter_file" "$receiver_out" "$wrapper_log"
}

### Scenario A: succeeds on attempt 1, no escalation
run_scenario "succeed-first-try" "PR_REVIEW" 'export FAKE_AGENT_MODE=succeed'
assert_eq "$OUTCOME" "PASSED" "A: outcome"
assert_eq "$ATTEMPTS" "1" "A: attempts_made"
assert_eq "$WRAPPER_EXIT" "0" "A: wrapper exit code"
assert_eq "$ESCALATED" "0" "A: no escalation sent"

### Scenario B: fails twice (no test, then broken compile), succeeds on 3rd
run_scenario "fail-twice-then-succeed" "PR_REVIEW" \
  'export FAKE_AGENT_SEQUENCE=fail_no_test,fail_broken_compile,succeed'
assert_eq "$OUTCOME" "PASSED" "B: outcome"
assert_eq "$ATTEMPTS" "3" "B: attempts_made"
assert_eq "$WRAPPER_EXIT" "0" "B: wrapper exit code"
assert_eq "$ESCALATED" "0" "B: no escalation sent"

### Scenario C: exhaustion in PR_REVIEW -> severity page
run_scenario "exhaustion-pr-review" "PR_REVIEW" 'export FAKE_AGENT_MODE=fail_always'
assert_eq "$OUTCOME" "FAILED" "C: outcome"
assert_eq "$ATTEMPTS" "3" "C: attempts_made"
assert_eq "$WRAPPER_EXIT" "1" "C: wrapper exit code"
assert_eq "$ESCALATED" "1" "C: escalation sent exactly once"
if grep -q '"reason": "EXHAUSTION"' <<< "$ESCALATION_PAYLOAD" && grep -q '"severity": "page"' <<< "$ESCALATION_PAYLOAD"; then
  echo "PASS: C: escalation payload reason=EXHAUSTION severity=page"
else
  echo "FAIL: C: escalation payload wrong: $ESCALATION_PAYLOAD"
  FAILURES=$((FAILURES + 1))
fi

### Scenario D: exhaustion in AUTONOMOUS -> severity critical
run_scenario "exhaustion-autonomous" "AUTONOMOUS" 'export FAKE_AGENT_MODE=fail_always'
assert_eq "$OUTCOME" "FAILED" "D: outcome"
if grep -q '"severity": "critical"' <<< "$ESCALATION_PAYLOAD"; then
  echo "PASS: D: escalation payload severity=critical"
else
  echo "FAIL: D: escalation payload wrong: $ESCALATION_PAYLOAD"
  FAILURES=$((FAILURES + 1))
fi

### Scenario E: malformed JSON counts as a failed attempt, still exhausts
run_scenario "malformed-json" "PR_REVIEW" 'export FAKE_AGENT_MODE=malformed_json'
assert_eq "$OUTCOME" "FAILED" "E: outcome"
assert_eq "$ATTEMPTS" "3" "E: attempts_made"
assert_eq "$ESCALATED" "1" "E: escalation sent exactly once"

### Scenario F: fixes the bug but never writes a test -- rejected, not trusted
run_scenario "no-test-file-rejected" "PR_REVIEW" 'export FAKE_AGENT_MODE=fail_no_test'
assert_eq "$OUTCOME" "FAILED" "F: outcome (fix without test must not pass)"
assert_eq "$ATTEMPTS" "3" "F: attempts_made"

### Scenario G: test file written outside manifest_dir -- must not satisfy the gate
run_scenario "test-file-wrong-dir-rejected" "PR_REVIEW" 'export FAKE_AGENT_MODE=fail_test_wrong_dir'
assert_eq "$OUTCOME" "FAILED" "G: outcome (stray test file elsewhere must not pass)"
assert_eq "$ATTEMPTS" "3" "G: attempts_made"

### Scenario H: test file written via a staged git rename -- must still satisfy the gate
run_scenario "test-file-via-rename-accepted" "PR_REVIEW" 'export FAKE_AGENT_MODE=succeed_via_rename'
assert_eq "$OUTCOME" "PASSED" "H: outcome (renamed-into-place test file must count)"
assert_eq "$ATTEMPTS" "1" "H: attempts_made"

echo ""
if [[ "$FAILURES" -eq 0 ]]; then
  echo "ALL PASS"
  exit 0
else
  echo "$FAILURES FAILURE(S)"
  exit 1
fi
