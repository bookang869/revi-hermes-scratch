#!/usr/bin/env bash
# End-to-end test of autonomous-promote.sh (PLAN 4.2/4.3 "done when": a
# patch that breaks a seeded existing test triggers workspace abandonment +
# branch pruning + REGRESSION escalation with main untouched; a full-pass
# run lands a Verified merge commit with no human touch). Uses a local bare
# repo as the git remote and a fake GitHub API server, same pattern as
# test_promote_pr.sh.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMOTE="$SCRIPT_DIR/autonomous-promote.sh"

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

assert_not_contains() {
  local haystack="$1" needle="$2" label="$3"
  if grep -qF -- "$needle" <<< "$haystack"; then
    echo "FAIL: $label -- did not expect to find '$needle' in: $haystack"
    FAILURES=$((FAILURES + 1))
  else
    echo "PASS: $label"
  fi
}

# Sets up a bare "origin" + a checked-out working repo, a fake GitHub API
# (seeded with a merge http status/sha), and a mock escalation receiver,
# then runs autonomous-promote.sh and echoes everything the assertions need.
run_scenario() {
  local name="$1" test_command="$2" merge_http_status="$3"
  echo ""
  echo "=== scenario: $name ==="

  local origin; origin="$(mktemp -d)"
  git init -q --bare "$origin"
  local repo; repo="$(mktemp -d)"
  ( cd "$repo" && git init -q -b main && git remote add origin "$origin" \
      && echo seed > seed.txt && git add -A \
      && git -c user.email=t@t -c user.name=t commit -qm seed \
      && git push -q origin main )
  echo "fix" >> "$repo/seed.txt"  # simulates the wrapper's uncommitted patch

  local api_port=$((PORT_BASE + 1)); PORT_BASE=$api_port
  local recv_port=$((PORT_BASE + 1)); PORT_BASE=$recv_port
  local api_out; api_out="$(mktemp)"
  local recv_out; recv_out="$(mktemp)"
  local gh_output; gh_output="$(mktemp)"

  python3 "$SCRIPT_DIR/fake-github-api.py" "$api_port" "" "$merge_http_status" "test-merge-sha" > "$api_out" 2>&1 &
  local api_pid=$!
  python3 "$SCRIPT_DIR/mock_receiver.py" "autonomous-test-secret" "$recv_port" > "$recv_out" 2>&1 &
  local recv_pid=$!
  sleep 0.3

  ( export GITHUB_WORKSPACE="$repo"
    export GITHUB_TOKEN_HERMES="dummy-hermes-token"
    export GITHUB_TOKEN_PROD="dummy-prod-token"
    export GITHUB_REPOSITORY="fake-owner/fake-repo"
    export GITHUB_API_BASE_URL="http://127.0.0.1:$api_port"
    export ALERT_ID="test-$name" SERVICE_NAME="fixture-svc"
    export ERROR_SUMMARY="invalid memory address or nil pointer dereference"
    export SUMMARY="fixed the nil check" CONFIDENCE_NOTE="high" ATTEMPTS_MADE="1"
    export TEST_COMMAND="$test_command" MANIFEST_DIR="$repo"
    export REVI_ESCALATION_WEBHOOK_URL="http://127.0.0.1:$recv_port"
    export REVI_ESCALATION_WEBHOOK_SECRET="autonomous-test-secret"
    export GITHUB_OUTPUT="$gh_output"
    bash "$PROMOTE" > /dev/null 2>&1
  )
  local promote_exit=$?

  sleep 0.3
  kill "$api_pid" "$recv_pid" 2>/dev/null
  wait "$api_pid" "$recv_pid" 2>/dev/null

  PROMOTE_EXIT="$promote_exit"
  OUTCOME_OUTPUT="$(grep '^outcome=' "$gh_output" 2>/dev/null | cut -d= -f2-)"
  MERGE_SHA_OUTPUT="$(grep '^merge_sha=' "$gh_output" 2>/dev/null | cut -d= -f2-)"
  API_LOG="$(cat "$api_out" 2>/dev/null)"
  ESCALATION_PAYLOAD="$(grep 'RECEIVED_PAYLOAD' "$recv_out" 2>/dev/null || echo '')"
  PUSHED_BRANCH="$(git -C "$origin" branch --list "hermes/hotfix-test-$name")"

  rm -rf "$origin" "$repo" "$api_out" "$recv_out" "$gh_output"
}

### Scenario A: test grid + merge both pass -- Verified merge, no escalation
run_scenario "clean-merge" "true" "201"
assert_eq "$PROMOTE_EXIT" "0" "A: autonomous-promote.sh exit code"
assert_contains "$PUSHED_BRANCH" "hermes/hotfix-test-clean-merge" "A: hotfix branch pushed to origin"
assert_contains "$API_LOG" "MERGE_PAYLOAD" "A: merge API call made"
assert_contains "$API_LOG" "\"base\": \"main\"" "A: merge targets main"
assert_eq "$OUTCOME_OUTPUT" "MERGED" "A: outcome output"
assert_eq "$MERGE_SHA_OUTPUT" "test-merge-sha" "A: merge_sha output"
assert_eq "$ESCALATION_PAYLOAD" "" "A: no escalation on a clean merge"

### Scenario B: test grid fails -- abandon, prune branch, escalate REGRESSION
run_scenario "regression" "false" "201"
assert_eq "$PROMOTE_EXIT" "1" "B: autonomous-promote.sh exit code"
assert_not_contains "$API_LOG" "MERGE_PAYLOAD" "B: merge never attempted"
assert_contains "$API_LOG" "DELETE_REF_CALLED" "B: hotfix branch force-deleted"
assert_eq "$OUTCOME_OUTPUT" "FAILED" "B: outcome output"
assert_contains "$ESCALATION_PAYLOAD" "\"reason\": \"REGRESSION\"" "B: escalation reason"
assert_contains "$ESCALATION_PAYLOAD" "\"severity\": \"critical\"" "B: escalation severity"

### Scenario C: test grid passes but the merge API call itself is rejected
run_scenario "merge-rejected" "true" "409"
assert_eq "$PROMOTE_EXIT" "1" "C: autonomous-promote.sh exit code"
assert_contains "$API_LOG" "MERGE_PAYLOAD" "C: merge API call attempted"
assert_not_contains "$API_LOG" "DELETE_REF_CALLED" "C: branch left in place for manual inspection"
assert_eq "$OUTCOME_OUTPUT" "FAILED" "C: outcome output"
assert_contains "$ESCALATION_PAYLOAD" "\"reason\": \"MERGE_REJECTED\"" "C: escalation reason"
assert_contains "$ESCALATION_PAYLOAD" "\"severity\": \"critical\"" "C: escalation severity"

echo ""
if [[ "$FAILURES" -eq 0 ]]; then
  echo "ALL PASS"
  exit 0
else
  echo "$FAILURES FAILURE(S)"
  exit 1
fi
